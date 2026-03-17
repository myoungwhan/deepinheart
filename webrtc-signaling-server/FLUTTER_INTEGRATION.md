# Flutter Client Integration Guide

This document explains how the WebRTC signaling server integrates with the Flutter mobile application.

## Expected Socket.IO Events

The Flutter `signaling_client.dart` expects the following events from the server:

### Server → Client Events

**1. room-joined**
```javascript
// Server sends when user successfully joins a room
socket.emit('room-joined', {
  room: 'consultnow_123',
  userId: 'user456'
});
```

**2. user-joined**
```javascript
// Server sends when another user joins the room
socket.emit('user-joined', {
  userId: 'user789',
  room: 'consultnow_123'
});
```

**3. user-left**
```javascript
// Server sends when a user leaves the room
socket.emit('user-left', {
  userId: 'user789',
  room: 'consultnow_123'
});
```

**4. room-left**
```javascript
// Server sends when user successfully leaves a room
socket.emit('room-left', {
  room: 'consultnow_123',
  userId: 'user456'
});
```

**5. message** (Forwarded signaling messages)
```javascript
// Server forwards offer/answer/ice-candidate messages
socket.emit('message', {
  type: 'offer',           // 'offer', 'answer', or 'ice-candidate'
  data: {
    sdp: 'v=0\r\no=- 123456789 2 IN IP4 127.0.0.1\r\n...'
    // or for ice-candidate:
    // candidate: 'candidate:1 1 UDP 2130706431 192.168.1.100 54400 typ host',
    // sdpMid: '0',
    // sdpMLineIndex: 0
  },
  room: 'consultnow_123',
  from: 'user789',
  to: 'user456',
  timestamp: '2024-03-17T04:26:00.000Z'
});
```

**6. error**
```javascript
// Server sends error messages
socket.emit('error', {
  message: 'Room is full'
});
```

### Client → Server Events

**1. join-room**
```javascript
// Flutter client sends to join a room
socket.emit('join-room', {
  room: 'consultnow_123',
  userId: 'user456'
});
```

**2. leave-room**
```javascript
// Flutter client sends to leave a room
socket.emit('leave-room', {
  room: 'consultnow_123',
  userId: 'user456'
});
```

**3. send-message** (Signaling messages)
```javascript
// Flutter client sends offer/answer/ice-candidate
socket.emit('send-message', {
  type: 'offer',
  room: 'consultnow_123',
  from: 'user456',
  to: 'user789',
  data: {
    sdp: 'v=0\r\no=- 123456789 2 IN IP4 127.0.0.1\r\n...'
    // or for ice-candidate:
    // candidate: 'candidate:1 1 UDP 2130706431 192.168.1.100 54400 typ host',
    // sdpMid: '0',
    // sdpMLineIndex: 0
  }
});
```

## Flutter Client Code Flow

### 1. Connection

```dart
// In signaling_client.dart
await _socket.connect(signalingUrl, userId);

// Server responds with connection event
socket.on('connect', (_) {
  // Connection established
});
```

### 2. Join Room

```dart
// Flutter client joins room
await _signalingClient.joinRoom('consultnow_123');

// Server responds
socket.on('room-joined', (data) {
  // Successfully joined room
});

// Other users in room get notified
socket.on('user-joined', (data) {
  // Another user joined: data.userId
});
```

### 3. Offer/Answer Exchange

**Caller sends offer:**
```dart
// Flutter client creates and sends offer
final offer = await _peerConnection.createOffer();
await _peerConnection.setLocalDescription(offer);

await _signalingClient.sendOffer(targetUserId, offer.toMap());
```

**Server forwards to callee:**
```javascript
// Server receives send-message event
socket.emit('send-message', {
  type: 'offer',
  room: 'consultnow_123',
  from: 'user456',
  to: 'user789',
  data: offer.toMap()
});

// Server forwards to target user
targetSocket.emit('message', {
  type: 'offer',
  data: offer.toMap(),
  from: 'user456',
  to: 'user789',
  room: 'consultnow_123'
});
```

**Callee receives and responds:**
```dart
// Flutter client receives offer
socket.on('message', (data) {
  if (data['type'] == 'offer') {
    // Handle offer
    final offer = RTCSessionDescription(data['data']['sdp'], 'offer');
    await _peerConnection.setRemoteDescription(offer);
    
    // Create and send answer
    final answer = await _peerConnection.createAnswer();
    await _peerConnection.setLocalDescription(answer);
    
    await _signalingClient.sendAnswer(data['from'], answer.toMap());
  }
});
```

### 4. ICE Candidate Exchange

```dart
// When local ICE candidate is generated
_peerConnection.onIceCandidate = (candidate) {
  if (_remoteUserId != null) {
    await _signalingClient.sendIceCandidate(_remoteUserId!, candidate.toMap());
  }
};

// When remote ICE candidate is received
socket.on('message', (data) {
  if (data['type'] == 'ice-candidate') {
    final candidate = RTCIceCandidate(
      data['data']['candidate'],
      data['data']['sdpMid'],
      data['data']['sdpMLineIndex'],
    );
    await _peerConnection.addCandidate(candidate);
  }
});
```

## Message Flow Example

### Complete Call Flow

```
1. User A connects to server
2. User B connects to server
3. User A joins room "consultnow_123"
   Server: room-joined → User A
4. User B joins room "consultnow_123"
   Server: room-joined → User B
   Server: user-joined → User A (notifying B joined)
5. User A creates offer and sends
   Client A: send-message (offer) → Server
   Server: message (offer) → Client B
6. User B receives offer, creates answer
   Client B: send-message (answer) → Server
   Server: message (answer) → Client A
7. Both users exchange ICE candidates
   Client A: send-message (ice-candidate) → Server → Client B
   Client B: send-message (ice-candidate) → Server → Client A
8. WebRTC connection established
9. User A leaves call
   Client A: leave-room → Server
   Server: room-left → Client A
   Server: user-left → Client B
```

## Error Handling

### Server Errors

```dart
// Flutter client handles server errors
socket.on('error', (data) {
  print('Server error: ${data['message']}');
  // Handle: 'Room is full', 'User not in room', etc.
});
```

### Common Error Scenarios

**Room Full:**
```javascript
// Server sends error
socket.emit('error', { message: 'Room is full' });
```

**Invalid Message:**
```javascript
// Server validates and rejects invalid messages
socket.emit('error', { message: 'Invalid message format' });
```

**User Not in Room:**
```javascript
// Server checks permissions
socket.emit('error', { message: 'User not in room' });
```

## Configuration

### Server URL

Update Flutter configuration to point to your signaling server:

```dart
// In webrtc_config.dart or settings
static const String defaultSignalingUrl = 'ws://your-domain.com:3000';

// Or use HTTPS for production
static const String defaultSignalingUrl = 'wss://your-domain.com';
```

### Room ID Format

The server expects room IDs in format:
```
consultnow_appointmentId
```

Flutter client generates this using:
```dart
// In webrtc_config.dart
static String generateRoomId(int appointmentId) {
  return 'consultnow_$appointmentId';
}
```

## Testing the Integration

### 1. Start Server

```bash
cd webrtc-signaling-server
npm install
npm start
```

### 2. Configure Flutter

Update signaling URL in Flutter app:
```dart
final signalingUrl = 'ws://localhost:3000';
```

### 3. Test Connection

```dart
// Test basic connection
await _signalingClient.connect(signalingUrl, 'test-user-1');
await _signalingClient.joinRoom('consultnow_123');

// Should receive:
// - room-joined event
// - user-joined event (when second user joins)
```

### 4. Test WebRTC Flow

1. Two users join same room
2. User 1 sends offer
3. User 2 receives offer and sends answer
4. User 1 receives answer
5. Both exchange ICE candidates
6. WebRTC connection established

## Debugging

### Server Logs

Enable debug logging to see message flow:
```bash
DEBUG=* npm start
```

### Flutter Logs

Add logging to Flutter client:
```dart
debugPrint('📨 Received signaling message: ${message.type.name}');
```

### Common Issues

**Connection failed:**
- Check server is running
- Verify URL format (ws:// vs wss://)
- Check CORS settings

**Room join failed:**
- Verify room ID format
- Check room capacity (max 2 users)
- Validate user ID

**Message forwarding failed:**
- Ensure both users are in same room
- Verify target user ID is correct
- Check message format

This integration guide ensures the Flutter WebRTC client works seamlessly with the signaling server for peer-to-peer communication.
