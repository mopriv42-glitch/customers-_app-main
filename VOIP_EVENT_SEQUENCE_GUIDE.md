# دليل تسلسل أحداث VoIP في Matrix

## المشكلة الأصلية

كانت المشكلة في تسلسل الأحداث عند قبول المكالمة، حيث يتم إرسال ICE candidates قبل أن يكون الطرف الآخر جاهزاً لاستقبالها.

## التسلسل الصحيح للأحداث

### 1. عند بدء المكالمة (Caller - Element Web)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. إنشاء PeerConnection                                      │
│ 2. الحصول على Media Stream (Audio)                          │
│ 3. إنشاء Offer                                               │
│ 4. تعيين Local Description                                   │
│ 5. إرسال Offer عبر Matrix (m.call.invite)                   │
│ 6. بدء ICE Gathering                                         │
│ 7. إرسال ICE Candidates (m.call.candidates)                 │
└─────────────────────────────────────────────────────────────┘
```

### 2. عند استقبال المكالمة (Callee - Flutter App)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. استقبال Offer عبر Matrix (m.call.invite)                 │
│ 2. إنشاء PeerConnection                                      │
│ 3. الحصول على Media Stream (Audio)                          │
│ 4. تعيين Remote Description (من Offer)                      │
│ 5. إنشاء Answer                                              │
│ 6. تعيين Local Description (Answer)                         │
│ 7. إرسال Answer عبر Matrix (m.call.answer)                  │
│ 8. بدء ICE Gathering                                         │
│ 9. إرسال ICE Candidates (m.call.candidates)                 │
└─────────────────────────────────────────────────────────────┘
```

### 3. معالجة ICE Candidates

```
┌─────────────────────────────────────────────────────────────┐
│ 1. استقبال ICE Candidates من الطرف الآخر                   │
│ 2. التحقق من وجود Remote Description                        │
│ 3. إضافة ICE Candidates إلى PeerConnection                  │
│ 4. بدء ICE Connection Process                               │
│ 5. إنشاء ICE Connection                                     │
│ 6. بدء تدفق الصوت                                           │
└─────────────────────────────────────────────────────────────┘
```

## التحسينات المطبقة

### 1. تحسين إرسال ICE Candidates

**قبل التحسين:**

```dart
_pc!.onIceCandidate = (RTCIceCandidate c) async {
  // إرسال فوري للـ ICE candidate
  await room.sendEvent(content, type: EventTypes.CallCandidates);
};
```

**بعد التحسين:**

```dart
_pc!.onIceCandidate = (RTCIceCandidate c) async {
  // التحقق من وجود Local Description قبل الإرسال
  if (_pc?.getLocalDescription() != null) {
    await room.sendEvent(content, type: EventTypes.CallCandidates);
  } else {
    // تخزين مؤقت للـ ICE candidates
    _queueIceCandidate(c);
  }
};
```

### 2. إرسال ICE Candidates المؤقتة

```dart
// إرسال ICE candidates المؤقتة بعد تعيين Local Description
await _pc!.setLocalDescription(answer);
await _sendQueuedIceCandidates(); // إرسال المؤقتة
```

### 3. تحسين معالجة ICE Candidates الواردة

```dart
case EventTypes.CallCandidates:
  // التحقق من وجود جلسة نشطة
  if (session == null || session.callId != callId || list == null) {
    debugPrint('No active session found for ICE candidates');
    return;
  }

  // معالجة كل ICE candidate مع معالجة الأخطاء
  for (final c in list) {
    try {
      await session.addIceCandidate(c);
    } catch (e) {
      debugPrint('Error processing ICE candidate: $e');
    }
  }
```

### 4. مراقبة حالة ICE Connection

```dart
_pc!.onIceConnectionState = (RTCIceConnectionState state) {
  switch (state) {
    case RTCIceConnectionState.RTCIceConnectionStateFailed:
      debugPrint('ICE connection failed - this may cause audio issues');
      break;
    case RTCIceConnectionState.RTCIceConnectionStateConnected:
      debugPrint('ICE connection established - audio should work now');
      break;
    // ... حالات أخرى
  }
};
```

## التسلسل الزمني المتوقع

### للمكالمة الواردة من Element Web:

```
T0: استقبال m.call.invite
T1: إنشاء PeerConnection
T2: الحصول على Media Stream
T3: تعيين Remote Description
T4: إنشاء Answer
T5: تعيين Local Description
T6: إرسال m.call.answer
T7: إرسال ICE candidates المؤقتة
T8: استقبال ICE candidates من Element
T9: إضافة ICE candidates
T10: إنشاء ICE connection
T11: بدء تدفق الصوت
```

## نصائح للاختبار

### 1. مراقبة السجلات

راقب السجلات للتأكد من التسلسل الصحيح:

```
- "Generated ICE candidate: ..."
- "Sent ICE candidate via Matrix: ..."
- "Received ICE candidates: ..."
- "ICE connection established - audio should work now"
```

### 2. اختبار الحالات المختلفة

- التطبيق في المقدمة
- التطبيق في الخلفية
- التطبيق مغلق تماماً

### 3. مراقبة حالة ICE Connection

تأكد من وصول ICE connection إلى حالة "Connected" أو "Completed"

## الخلاصة

التحسينات المطبقة تضمن:

1. ✅ التسلسل الصحيح لإرسال ICE candidates
2. ✅ معالجة أفضل للأخطاء
3. ✅ مراقبة مفصلة لحالة الاتصال
4. ✅ تحسين استقرار المكالمات
5. ✅ تسجيل مفصل لتسهيل التشخيص

هذه التحسينات يجب أن تحل مشكلة الصوت في المكالمات الواردة من Element Web.
