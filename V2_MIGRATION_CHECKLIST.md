# ✅ PortOne V2 Migration Checklist

## 🎯 Migration Complete - What to Do Next

### ✅ Already Done:
- [x] Updated `pubspec.yaml` to use `portone_flutter_v2: ^1.1.0`
- [x] Updated imports in `payment_provider.dart`
- [x] Converted `IamportPayment` to `PortonePayment`
- [x] Converted `PaymentData` to `PaymentRequest`
- [x] Updated callback structure (separate success/error)
- [x] Updated `payment_config.dart` with V2 credentials
- [x] Removed Naver Pay (old V1 implementation)
- [x] Ran `flutter pub get` successfully
- [x] No linter errors

---

## 📝 What You Need to Do:

### 1. Get PortOne V2 Credentials (IMPORTANT!)

Currently using **placeholder credentials**. You must update these:

```dart
// In lib/config/payment_config.dart

// ❌ Current (PLACEHOLDER - WON'T WORK!)
static const String KAKAO_TEST_STORE_ID = 'store-00000000-0000-0000-0000-000000000000';
static const String KAKAO_TEST_CHANNEL_KEY = 'channel-key-00000000-0000-0000-0000-000000000000';

// ✅ Replace with YOUR ACTUAL credentials from PortOne Console
static const String KAKAO_TEST_STORE_ID = 'your-actual-store-id';
static const String KAKAO_TEST_CHANNEL_KEY = 'your-actual-channel-key';
```

**How to get credentials:**
1. Go to https://console.portone.io/
2. Sign up / Log in
3. Create a new store (or use existing)
4. Go to "Channels" → "Add Channel"
5. Select "Kakao Pay"
6. Copy your `Store ID` and `Channel Key`

---

### 2. Test the Payment Flow

```bash
# Run the app
cd deepinheart_clone
flutter run
```

**Test Steps:**
1. Go to coin charging screen
2. Select a coin package (e.g., 100 coins)
3. Click "Kakao Pay (카카오페이)"
4. Click "Charge" button
5. **Check for errors in console**
6. Complete payment in WebView
7. Verify coins are added

**Expected Console Output:**
```
==================================================
Initiating Kakao Pay Payment (V2)
Payment ID: payment-1768xxxxxxx
Amount: 10000 KRW
Coins: 100
Store ID: store-xxxx-xxxx-xxxx-xxxx
Channel Key: channel-key-xxxx-xxxx-xxxx-xxxx
==================================================
```

---

### 3. Verify Platform Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`):
Check these exist:
```xml
<!-- Internet permission -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Package queries for payment apps -->
<queries>
  <package android:name="com.kakao.talk" />
  <!-- Other payment apps... -->
</queries>

<!-- App scheme for deep linking -->
<activity android:name=".MainActivity">
  <intent-filter>
    <data android:scheme="deepinheart" />
  </intent-filter>
</activity>
```

#### iOS (`ios/Runner/Info.plist`):
Check these exist:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaotalk</string>
</array>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>deepinheart</string>
    </array>
  </dict>
</array>
```

---

### 4. When Ready for Production

Update `payment_config.dart`:
```dart
// Change to live mode
static const bool IS_LIVE = true;

// Add live credentials
static const String KAKAO_LIVE_STORE_ID = 'your-live-store-id';
static const String KAKAO_LIVE_CHANNEL_KEY = 'your-live-channel-key';
```

---

## 🚨 Common Issues & Solutions

### Issue: "Store ID not found"
**Cause**: Using placeholder credentials  
**Fix**: Update with actual credentials from PortOne Console

### Issue: Payment screen shows error
**Cause**: Invalid channel key or store ID mismatch  
**Fix**: Verify credentials match in PortOne console

### Issue: Payment completes but coins not added
**Cause**: Backend API integration  
**Fix**: Check API logs and `_handlePaymentSuccess` method

---

## 📊 Migration Status

| Component | Status | Notes |
|-----------|--------|-------|
| Package | ✅ Done | `portone_flutter_v2: ^1.1.0` |
| Imports | ✅ Done | Updated to V2 API |
| Widget | ✅ Done | `PortonePayment` |
| Data Model | ✅ Done | `PaymentRequest` |
| Callbacks | ✅ Done | Separate success/error |
| Config | ⚠️ Needs Update | Replace placeholder credentials |
| Android Manifest | ✅ Done | Should auto-configure |
| iOS Info.plist | ⚠️ Check | Verify schemes exist |
| Testing | ⏳ Pending | Test with real credentials |

---

## 🎯 Next Steps (In Order)

1. **Get Credentials** → PortOne Console → Copy Store ID & Channel Key
2. **Update Config** → `payment_config.dart` → Replace placeholders
3. **Run App** → `flutter run` → Test payment flow
4. **Verify** → Check console logs → Ensure no errors
5. **Test Payment** → Complete test transaction → Verify coins added
6. **Go Live** → Set `IS_LIVE = true` → Test with real payment

---

## 🎉 Summary

### What Works Now:
- ✅ V2 API integration complete
- ✅ Clean, modern code structure
- ✅ Better error handling
- ✅ Type-safe enums
- ✅ Simplified loading screen
- ✅ Active package (not discontinued)

### What You Need:
- ⚠️ **Real PortOne V2 credentials**
- ⚠️ Test payment to verify everything works
- ⚠️ Monitor first few transactions

---

## 📞 Quick Commands

```bash
# Install dependencies
flutter pub get

# Clean build
flutter clean && flutter pub get

# Run app
flutter run

# Check for issues
flutter analyze
```

---

## 📚 Documentation

- Full Setup Guide: `PORTONE_V2_SETUP.md`
- PortOne Console: https://console.portone.io/
- Package Docs: https://pub.dev/packages/portone_flutter_v2

---

**You're almost there! Just need to add your PortOne V2 credentials and test!** 🚀

Good luck! 🎊

