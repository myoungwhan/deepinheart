const { Server } = require("socket.io");
const http = require("http");
const cors = require("cors");
const helmet = require("helmet");

// Security middleware
const app = require("express")();
app.use(helmet());
app.use(cors());

// Create HTTP server
const server = http.createServer(app);

// Socket.IO configuration
const io = new Server(server, {
  cors: {
    origin: "*", // Configure this for production
    methods: ["GET", "POST"],
    credentials: true
  },
  transports: ["websocket", "polling"],
  pingTimeout: 60000,
  pingInterval: 25000
});

// Room management
const rooms = new Map();
const MAX_USERS_PER_ROOM = 2;

// Utility functions
function logEvent(event, data = {}) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${event}:`, data);
}

function validateRoom(roomId) {
  if (!roomId || typeof roomId !== 'string') {
    return false;
  }
  return true;
}

function validateMessage(message) {
  if (!message || typeof message !== 'object') {
    return false;
  }
  if (!message.type || !message.room || !message.from) {
    return false;
  }
  return true;
}

function getRoomInfo(roomId) {
  const room = rooms.get(roomId);
  if (!room) {
    return null;
  }
  
  const users = Array.from(room.users.values());
  return {
    roomId,
    userCount: users.length,
    users: users.map(user => ({
      userId: user.userId,
      socketId: user.socketId,
      joinedAt: user.joinedAt
    }))
  };
}

function cleanupRoom(roomId) {
  const room = rooms.get(roomId);
  if (room && room.users.size === 0) {
    rooms.delete(roomId);
    logEvent('Room cleaned up', { roomId });
  }
}

// Socket.IO connection handler
io.on("connection", (socket) => {
  logEvent('User connected', { socketId: socket.id });

  // Store user info in socket
  socket.userData = {
    userId: null,
    roomId: null,
    joinedAt: null
  };

  // Handle join-room event
  socket.on('join-room', async (data) => {
    try {
      const { room, userId } = data;
      
      logEvent('Join room request', { socketId: socket.id, userId, room });

      // Validate input
      if (!validateRoom(room) || !userId) {
        socket.emit('error', { message: 'Invalid room or user ID' });
        return;
      }

      // Get or create room
      let roomData = rooms.get(room);
      if (!roomData) {
        roomData = {
          roomId: room,
          users: new Map(),
          createdAt: new Date()
        };
        rooms.set(room, roomData);
        logEvent('Room created', { room });
      }

      // Check room capacity
      if (roomData.users.size >= MAX_USERS_PER_ROOM) {
        socket.emit('error', { message: 'Room is full' });
        logEvent('Room full', { room, userId });
        return;
      }

      // Check if user already in room
      if (roomData.users.has(userId)) {
        socket.emit('error', { message: 'User already in room' });
        return;
      }

      // Leave previous room if any
      if (socket.userData.roomId && socket.userData.userId) {
        await leaveRoom(socket, socket.userData.roomId, socket.userData.userId);
      }

      // Add user to room
      socket.userData.userId = userId;
      socket.userData.roomId = room;
      socket.userData.joinedAt = new Date();

      roomData.users.set(userId, {
        userId,
        socketId: socket.id,
        joinedAt: new Date()
      });

      // Join socket room
      socket.join(room);

      // Notify user they joined successfully
      socket.emit('room-joined', { room, userId });

      // Notify other users in the room
      const otherUsers = Array.from(roomData.users.keys()).filter(id => id !== userId);
      if (otherUsers.length > 0) {
        socket.to(room).emit('user-joined', { userId, room });
      }

      logEvent('User joined room', { 
        socketId: socket.id, 
        userId, 
        room, 
        userCount: roomData.users.size 
      });

      // Log room info
      const roomInfo = getRoomInfo(room);
      logEvent('Room status', roomInfo);

    } catch (error) {
      logEvent('Join room error', { error: error.message });
      socket.emit('error', { message: 'Failed to join room' });
    }
  });

  // Handle leave-room event
  socket.on('leave-room', async (data) => {
    try {
      const { room, userId } = data;
      
      if (socket.userData.roomId && socket.userData.userId) {
        await leaveRoom(socket, socket.userData.roomId, socket.userData.userId);
      }
      
    } catch (error) {
      logEvent('Leave room error', { error: error.message });
    }
  });

  // Handle send-message event (for offer, answer, ice-candidate)
  socket.on('send-message', async (data) => {
    try {
      // Validate message
      if (!validateMessage(data)) {
        socket.emit('error', { message: 'Invalid message format' });
        return;
      }

      const { type, room, from, to, data: messageData } = data;

      logEvent('Message received', { 
        socketId: socket.id, 
        type, 
        room, 
        from, 
        to 
      });

      // Verify user is in the room
      const roomData = rooms.get(room);
      if (!roomData || !roomData.users.has(from)) {
        socket.emit('error', { message: 'User not in room' });
        return;
      }

      // Verify target user exists in room
      if (!roomData.users.has(to)) {
        socket.emit('error', { message: 'Target user not in room' });
        return;
      }

      // Get target socket
      const targetUser = roomData.users.get(to);
      const targetSocket = io.sockets.sockets.get(targetUser.socketId);

      if (!targetSocket) {
        socket.emit('error', { message: 'Target user not connected' });
        return;
      }

      // Forward message to target user
      targetSocket.emit('message', {
        type,
        data: messageData,
        room,
        from,
        to,
        timestamp: new Date().toISOString()
      });

      logEvent('Message forwarded', { 
        type, 
        from, 
        to, 
        room 
      });

    } catch (error) {
      logEvent('Send message error', { error: error.message });
      socket.emit('error', { message: 'Failed to send message' });
    }
  });

  // Handle disconnection
  socket.on('disconnect', async (reason) => {
    logEvent('User disconnected', { 
      socketId: socket.id, 
      reason,
      userId: socket.userData.userId,
      room: socket.userData.roomId
    });

    // Leave room if user was in one
    if (socket.userData.roomId && socket.userData.userId) {
      await leaveRoom(socket, socket.userData.roomId, socket.userData.userId);
    }
  });

  // Handle connection errors
  socket.on('error', (error) => {
    logEvent('Socket error', { 
      socketId: socket.id, 
      error: error.message 
    });
  });
});

// Helper function to leave room
async function leaveRoom(socket, roomId, userId) {
  try {
    const roomData = rooms.get(roomId);
    if (!roomData) {
      return;
    }

    // Remove user from room
    roomData.users.delete(userId);
    socket.leave(roomId);

    // Notify other users
    socket.to(roomId).emit('user-left', { userId, room: roomId });

    // Clear user data
    socket.userData.userId = null;
    socket.userData.roomId = null;
    socket.userData.joinedAt = null;

    // Notify user they left
    socket.emit('room-left', { room: roomId, userId });

    logEvent('User left room', { 
      socketId: socket.id, 
      userId, 
      room: roomId,
      remainingUsers: roomData.users.size
    });

    // Cleanup empty room
    cleanupRoom(roomId);

    // Log room info
    const roomInfo = getRoomInfo(roomId);
    if (roomInfo) {
      logEvent('Room status after leave', roomInfo);
    }

  } catch (error) {
    logEvent('Leave room error', { error: error.message });
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  const roomStats = Array.from(rooms.values()).map(room => ({
    roomId: room.roomId,
    userCount: room.users.size,
    createdAt: room.createdAt
  }));

  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    totalRooms: rooms.size,
    totalConnections: io.engine.clientsCount,
    rooms: roomStats
  });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  logEvent('Server started', { 
    port: PORT,
    environment: process.env.NODE_ENV || 'development'
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logEvent('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logEvent('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logEvent('SIGINT received, shutting down gracefully');
  server.close(() => {
    logEvent('Server closed');
    process.exit(0);
  });
});

// Error handling
process.on('uncaughtException', (error) => {
  logEvent('Uncaught exception', { error: error.message, stack: error.stack });
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logEvent('Unhandled rejection', { reason, promise });
});
