# Azdal — Image Input Specification (Share Sheet + Camera)

> **Date:** 2026-05-19
> **Purpose:** Two-method image ingestion for zero-friction receipt processing

---

## Method A: Camera Button (In-App)

User is already in Azdal → taps `📷` → camera opens or gallery picker → image goes to OCR.

```
Azdal Chat Screen
    ↓ tap 📷
┌─────────────────┐
│ 📷 التقط صورة    │
│ 🖼 من المعرض     │
│ ✖️ إلغاء         │
└─────────────────┘
    ↓ select image
Gemini Vision OCR
    ↓ extract data
Inline result card in chat
```

### Flutter Implementation

```dart
import 'package:image_picker/image_picker.dart';

Future<void> captureReceipt() async {
  final picker = ImagePicker();
  
  // Show bottom sheet: Camera or Gallery
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(leading: Icon(Icons.camera), title: Text('التقط صورة'), 
                 onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ListTile(leading: Icon(Icons.photo_library), title: Text('من المعرض'),
                 onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ],
    ),
  );
  
  if (source == null) return;
  
  final file = await picker.pickImage(source: source);
  if (file == null) return;
  
  // Pre-process (Core Image: contrast, grayscale)
  // Send to Gemini Vision OCR
  final result = await processReceiptOCR(file.path);
  
  // Show result inline in chat
  addBotMessage(result);
}
```

---

## Method B: System Share Sheet (From Outside App)

User is in Gallery, Bank app, WhatsApp → taps Share → selects "Azdal" → app opens to chat → OCR processes automatically.

```
Gallery / Bank App / WhatsApp
    ↓ tap Share
┌─────────────────────┐
│ مشاركة إلى...        │
│  ...                │
│  🜔 أزدل            │  ← Azdal appears in share sheet
│  ...                │
└─────────────────────┘
    ↓
Azdal opens → OCR processes automatically
    ↓
Inline result card in chat
```

### Android — Intent Filter

```xml
<!-- AndroidManifest.xml -->
<activity 
    android:name=".ReceiptShareActivity"
    android:exported="true"
    android:theme="@style/Theme.App.Transparent">
    
    <!-- Single image share -->
    <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="image/*" />
    </intent-filter>
    
    <!-- Multiple images -->
    <intent-filter>
        <action android:name="android.intent.action.SEND_MULTIPLE" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="image/*" />
    </intent-filter>
</activity>
```

### iOS — Share Extension (Advanced)

For iOS, add a Share Extension target. Simpler for MVP: iOS users use the in-app camera/gallery button.

```
iOS MVP: Use in-app button only (simpler)
iOS Production: Add Share Extension target
```

### Flutter — Receive Sharing Intent

```dart
// pubspec.yaml: receive_sharing_intent: ^1.8.0

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void initShareHandler() {
  // For cold start (app not running)
  ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> files) {
    if (files.isNotEmpty) {
      processReceiptOCR(files.first.path);
    }
  });

  // For warm start (app in background)
  ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> files) {
    if (files.isNotEmpty) {
      processReceiptOCR(files.first.path);
    }
  });
}
```

---

## OCR Processing Pipeline

```
Image received (either method)
    ↓
Pre-process (Optional — Core Image)
    - Grayscale conversion
    - Contrast enhancement
    - Deskew
    ↓
Gemini Vision API (Flash)
    - System prompt: Arabic financial OCR
    - Extract: merchant, date, total, items
    - Output: structured JSON
    ↓
Deterministic Validation (Python)
    - Check: sum(line_items) == extracted_total
    - Flag mismatch (⚠️ warning)
    - Enforce category dictionary (13 categories)
    ↓
Inline result card in chat
    - Merchant + date + amount
    - Category picker (Quick Buttons)
    - User confirms → saved to transactions table
```

---

## MVP Decision

| Method | MVP? | Effort |
|--------|------|--------|
| Camera button (in-app) | ✅ Yes | 1 day |
| Share sheet (from outside) | ⚠️ If time permits (Week 4) | 1 day |
| iOS Share Extension | ❌ Post-MVP | 3+ days |

**Priority:** Ship camera button first. Add share sheet if time in Week 4. iOS extension post-hackathon.
