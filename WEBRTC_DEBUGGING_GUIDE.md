# WebRTC Connection Debugging Guide

## Issues Fixed

### 1. **Channel Name Validation**
- **Problem**: Channel name from API response (`response['chanel_id']`) could be null or empty
- **Solution**: Added validation in `counselor_detail_screen.dart`:
  - Check if `chanel_id` exists in API response
  - Convert to string and validate it's not empty
  - Show user-friendly error messages
  - Add detailed logging for API response debugging

### 2. **Parameter Validation in CallEngineSelector**
- **Problem**: No validation for critical parameters before navigation
- **Solution**: Added validation in `call_engine_selector.dart`:
  - Check `channelName` is not null or empty
  - Add detailed logging for all call parameters
  - Enable WebRTC debug mode in development
  - Show error snackbar if validation fails

### 3. **WebRTC Service Initialization Validation**
- **Problem**: No null checks for roomId and userId in WebRTC service
- **Solution**: Added validation in `webrtc_service.dart`:
  - Validate roomId and userId before initialization
  - Add comprehensive logging for connection parameters
  - Validate signaling server URL is not empty
  - Better error handling and user feedback

### 4. **Enhanced Logging**
- **Problem**: Insufficient debugging information for connection issues
- **Solution**: Added detailed logging throughout:
  - Call initialization parameters
  - Signaling server connection details
  - Room joining process
  - Stream setup status
  - Connection state changes

### 5. **Signaling Server URL Fallbacks**
- **Problem**: Single point of failure for signaling server
- **Solution**: Added fallback URLs in `webrtc_config.dart`:
  - Primary production URL
  - Local development URLs
  - WebSocket secure fallback

## Debugging Steps

When WebRTC connection fails, check these logs in order:

### 1. API Response Validation
```
🔍 API Response Validation:
   - Response: {...}
   - Channel ID: consultnow_345
   - Appointment ID: 123
```

### 2. CallEngineSelector Validation
```
🔍 validateParams - counselorName: John Doe, channelName: consultnow_345, userId: 123456
🚀 Navigating to video call with engine: webrtc
📞 Call Details:
   - Channel Name: consultnow_345
   - User ID: 123456
   - Counselor: John Doe
   - Appointment ID: 123
```

### 3. WebRTC Service Initialization
```
🎥 WebRTC Video Call Initialization:
   - Room ID: room_123
   - User ID: 123456789
   - Channel Name: consultnow_345
   - Appointment ID: 123
   - Counselor ID: 456
```

### 4. Signaling Client Connection
```
🔗 Signaling Server URL: http://158.247.241.227:3000
🏠 Room ID: room_123
👤 User ID: 123456789
✅ Signaling client connected, joining room...
```

## Common Issues & Solutions

### Issue: "Channel name is null or empty!"
**Cause**: API response missing `chanel_id` field
**Solution**: Check API response structure, ensure backend returns `chanel_id`

### Issue: "Signaling server URL is empty!"
**Cause**: Settings provider returns null or empty URL
**Solution**: Configure WebRTC signaling URL in admin panel or use default

### Issue: "Room ID is null when trying to join!"
**Cause**: WebRTC service initialization failed
**Solution**: Check appointment ID is being passed correctly

### Issue: Connection timeout
**Cause**: Signaling server unreachable
**Solution**: 
1. Check server is running at configured URL
2. Verify network connectivity
3. Try fallback URLs

## Testing Checklist

- [ ] API returns `chanel_id` field correctly
- [ ] Channel name is not null or empty
- [ ] Signaling server URL is configured in settings
- [ ] WebRTC debug mode shows detailed logs
- [ ] Room ID is generated from appointment ID
- [ ] User ID is generated correctly
- [ ] Local stream is initialized
- [ ] Signaling client connects successfully
- [ ] Room joining process completes

## Configuration Variables

Make sure these are properly configured:

```dart
// In admin panel settings
String webrtcSignalingUrl = 'http://158.247.241.227:3000';
String webrtcTurnServers = 'turn:user:pass@server:3478';

// In code
String channelId = 'consultnow_345';  // From API response
String roomId = 'room_123';           // Generated from appointment ID
String userId = '123456789';          // Generated timestamp
```

## Error Messages to Watch For

- `❌ Channel name is null or empty!` - API response issue
- `❌ Signaling server URL is empty!` - Configuration issue  
- `❌ Room ID is null when trying to join!` - Initialization issue
- `❌ Failed to connect to signaling server` - Network/server issue
- `⚠️ Local stream is null` - Media permissions/hardware issue
