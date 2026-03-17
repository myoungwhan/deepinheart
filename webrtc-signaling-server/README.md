# WebRTC Signaling Server

A Node.js signaling server for WebRTC peer-to-peer communication in the DeepInHeart mobile application.

## Features

- **Socket.IO** based real-time communication
- **Room management** with 2-user limit per room
- **Message forwarding** for WebRTC signaling
- **Security protections** and input validation
- **Health monitoring** and logging
- **Graceful shutdown** handling

## Quick Start

### Installation

```bash
cd webrtc-signaling-server
npm install
```

### Running the Server

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

The server will start on port 3000 by default.

### Environment Variables

```bash
PORT=3000              # Server port (default: 3000)
NODE_ENV=production    # Environment (default: development)
```

## API Documentation

### Socket.IO Events

#### Client → Server Events

**join-room**
```javascript
socket.emit('join-room', {
  room: 'consultnow_123',
  userId: 'user456'
});
```

**leave-room**
```javascript
socket.emit('leave-room', {
  room: 'consultnow_123',
  userId: 'user456'
});
```

**send-message** (for offer, answer, ice-candidate)
```javascript
socket.emit('send-message', {
  type: 'offer',           // 'offer', 'answer', or 'ice-candidate'
  room: 'consultnow_123',
  from: 'user456',
  to: 'user789',
  data: {
    sdp: '...'            // SDP data for offer/answer
    // or
    candidate: '...',      // ICE candidate data
    sdpMid: '...',
    sdpMLineIndex: 0
  }
});
```

#### Server → Client Events

**room-joined**
```javascript
socket.on('room-joined', (data) => {
  console.log('Joined room:', data.room);
});
```

**user-joined**
```javascript
socket.on('user-joined', (data) => {
  console.log('User joined:', data.userId);
});
```

**user-left**
```javascript
socket.on('user-left', (data) => {
  console.log('User left:', data.userId);
});
```

**room-left**
```javascript
socket.on('room-left', (data) => {
  console.log('Left room:', data.room);
});
```

**message** (forwarded signaling messages)
```javascript
socket.on('message', (data) => {
  console.log('Received:', data.type, 'from:', data.from);
  // Handle offer, answer, or ice-candidate
});
```

**error**
```javascript
socket.on('error', (data) => {
  console.error('Server error:', data.message);
});
```

### HTTP Endpoints

**Health Check**
```bash
GET /health
```

Returns server status and room statistics:
```json
{
  "status": "healthy",
  "timestamp": "2024-03-17T04:26:00.000Z",
  "totalRooms": 5,
  "totalConnections": 12,
  "rooms": [
    {
      "roomId": "consultnow_123",
      "userCount": 2,
      "createdAt": "2024-03-17T04:20:00.000Z"
    }
  ]
}
```

## Room Structure

### Room ID Format
```
consultnow_appointmentId
```

### Room Limits
- **Maximum users per room**: 2
- **Room cleanup**: Automatic when empty

### User Management
- Each user can only join one room at a time
- Users are identified by unique `userId`
- Duplicate users in same room are rejected

## Security Features

### Input Validation
- Room ID format validation
- Message structure validation
- User permission verification

### Access Control
- Users can only send messages to rooms they joined
- Target user verification for message forwarding
- Room capacity enforcement

### Error Handling
- Safe error messages to clients
- Comprehensive server-side logging
- Graceful degradation

## Deployment

### Local Development

```bash
npm install
npm run dev
```

### Production Deployment

**Using PM2:**
```bash
npm install -g pm2
pm2 start server.js --name "webrtc-signaling"
pm2 startup
pm2 save
```

**Using Docker:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### SSL/HTTPS Setup

For production, configure SSL with Let's Encrypt:
```bash
sudo certbot --nginx -d your-domain.com
```

## Monitoring

### Server Logs

The server provides detailed logging for:
- User connections/disconnections
- Room joins/leaves
- Message forwarding
- Errors and exceptions

Example log output:
```
[2024-03-17T04:26:00.000Z] User connected: { socketId: 'abc123' }
[2024-03-17T04:26:01.000Z] User joined room: { socketId: 'abc123', userId: 'user456', room: 'consultnow_123', userCount: 1 }
[2024-03-17T04:26:02.000Z] Message received: { socketId: 'abc123', type: 'offer', room: 'consultnow_123', from: 'user456', to: 'user789' }
[2024-03-17T04:26:02.000Z] Message forwarded: { type: 'offer', from: 'user456', to: 'user789', room: 'consultnow_123' }
```

### Health Monitoring

Monitor server health:
```bash
curl http://localhost:3000/health
```

## Flutter Client Integration

The server is designed to work with the Flutter `signaling_client.dart`:

```dart
// Flutter client connection
await _signalingClient.connect('ws://localhost:3000', userId);

// Join room
await _signalingClient.joinRoom('consultnow_123');

// Send offer
await _signalingClient.sendOffer(targetUserId, offerData);

// Listen for messages
_signalingClient.messageStream.listen((message) {
  // Handle offer, answer, ice-candidate
});
```

## Troubleshooting

### Common Issues

**Room full error:**
- Check if room has 2 users already
- Verify users are properly leaving rooms

**Connection failures:**
- Check server is running on correct port
- Verify CORS settings for production
- Check firewall/network configuration

**Message forwarding failures:**
- Verify both users are in the same room
- Check target user ID is correct
- Validate message format

### Debug Mode

Enable debug logging:
```bash
DEBUG=* npm start
```

## License

MIT License - see LICENSE file for details.
