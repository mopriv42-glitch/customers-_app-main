# نظام التحليلات وتتبع الأحداث - Analytics System

## نظرة عامة

تم تطبيق نظام تحليلات شامل لتتبع سلوك المستخدم في التطبيق بالتفصيل، مع إرسال البيانات إلى Laravel API بشكل فوري ومباشر لعرضها في لوحة التحكم.

## الميزات المطبّقة

### 1. تتبع الشبكة (Network Logging)

- ✅ تسجيل جميع طلبات API (Dio + http/ApiRequests)
- ✅ تسجيل Headers والـ Body للطلب والرد
- ✅ تسجيل وقت الاستجابة (Duration)
- ✅ تسجيل الأخطاء وحالات الفشل
- ✅ **إخفاء المفاتيح الحساسة** (password, token, etc.)

### 2. تتبع الشاشات (Screen Views)

- ✅ تسجيل تلقائي عند فتح أي شاشة
- ✅ تتبع التنقل بين الشاشات
- ✅ معرفة الشاشة الحالية في كل حدث

### 3. تتبع الأحداث (Events)

- ✅ تسجيل أحداث مخصصة في أي مكان
- ✅ دعم Properties لإضافة بيانات إضافية
- ✅ ربط كل حدث بالشاشة الحالية

### 4. معلومات الجلسة (Session Info)

- ✅ Device ID دائم (يبقى بعد إعادة تشغيل التطبيق)
- ✅ Session ID جديد لكل جلسة
- ✅ User ID (يتم تحديثه عند تسجيل الدخول)
- ✅ إرسال Headers مع كل طلب API

### 5. الخصوصية والأمان

- ✅ **Blocked Keys Approach**: إخفاء المفاتيح الحساسة
- ✅ قائمة قابلة للتخصيص في `analytics_config.dart`
- ✅ Truncation للبيانات الكبيرة (100KB max)

### 6. الأداء والموثوقية

- ✅ Batching: إرسال 20 حدث دفعة واحدة
- ✅ Auto-flush كل 25 ثانية
- ✅ Retry logic مع exponential backoff
- ✅ فحص الاتصال قبل الإرسال

## الملفات المُنشأة

```
lib/core/analytics/
├── analytics_config.dart           # إعدادات النظام والمفاتيح المحظورة
├── analytics_models.dart           # نماذج البيانات
├── analytics_service.dart          # الخدمة الرئيسية
├── analytics_network_interceptor.dart  # Dio interceptor
├── analytics_http_wrapper.dart     # http/ApiRequests wrapper
├── analytics_navigator_observer.dart   # تتبع الشاشات
├── analytics_helpers.dart          # دوال مساعدة
└── README_ANALYTICS.md            # هذا الملف
```

## كيفية الاستخدام

### 1. إضافة المفاتيح المحظورة

في `lib/core/analytics/analytics_config.dart`:

```dart
static List<String> blockedRequestBodyKeys = [
  'password',
  'pin',
  'cvv',
  'card_number',
  // أضف المزيد هنا
];

static List<String> blockedResponseBodyKeys = [
  'token',
  'access_token',
  'api_key',
  // أضف المزيد هنا
];
```

### 2. تسجيل حدث مخصص

```dart
import 'package:private_4t_app/core/analytics/analytics_service.dart';

// في أي مكان في التطبيق
AnalyticsService.instance.logEvent(
  'button_clicked',
  properties: {
    'button_name': 'submit',
    'form_type': 'registration',
  },
);
```

### 3. استخدام Helper Methods

```dart
import 'package:private_4t_app/core/analytics/analytics_helpers.dart';

// تسجيل ضغط زر
AnalyticsHelpers.logButtonTap(
  buttonId: 'next_step',
  screen: 'BookingOnlineScreen',
  additionalData: {'step': '2'},
);

// تسجيل خطوة حجز
AnalyticsHelpers.logBookingStep(
  step: 'select_grade',
  screen: 'BookingOnlineScreen',
  data: {'grade': 'الصف الأول', 'subject': 'رياضيات'},
);

// تسجيل Pull to Refresh
AnalyticsHelpers.logPullToRefresh(screen: 'HomeScreen');

// تسجيل إشعار
AnalyticsHelpers.logNotificationReceived(
  type: 'message',
  title: 'رسالة جديدة',
);

// تسجيل مكالمة VOIP
AnalyticsHelpers.logVoipCall(
  action: 'answer',
  callId: 'call-123',
  roomId: 'room-456',
  isVideo: true,
);
```

### 4. أمثلة للاستخدام في شاشات الحجز

```dart
// في existing_customer_online_screen.dart
import 'package:private_4t_app/core/analytics/analytics_helpers.dart';

class ExistingCustomerOnlineScreen extends StatelessWidget {

  void _onGradeSelected(String gradeId, String gradeName) {
    // تسجيل اختيار الصف
    AnalyticsHelpers.logBookingStep(
      step: 'grade_selected',
      screen: 'ExistingCustomerOnlineScreen',
      data: {
        'grade_id': gradeId,
        'grade_name': gradeName,
      },
    );

    // باقي الكود...
  }

  void _onSubjectSelected(String subjectId, String subjectName) {
    // تسجيل اختيار المادة
    AnalyticsHelpers.logBookingStep(
      step: 'subject_selected',
      screen: 'ExistingCustomerOnlineScreen',
      data: {
        'subject_id': subjectId,
        'subject_name': subjectName,
      },
    );
  }

  void _onNextButtonPressed() {
    // تسجيل الضغط على زر التالي
    AnalyticsHelpers.logButtonTap(
      buttonId: 'next_button',
      screen: 'ExistingCustomerOnlineScreen',
      additionalData: {
        'selected_grade': _selectedGrade,
        'selected_subject': _selectedSubject,
      },
    );

    // الانتقال للشاشة التالية
    context.push('/booking-summary');
  }
}
```

### 5. تسجيل الإشعارات والمكالمات

في `notification_service.dart`:

```dart
import 'package:private_4t_app/core/analytics/analytics_helpers.dart';

// عند استلام إشعار
static Future<void> showLocalFCMNotification(RemoteMessage message) async {
  AnalyticsHelpers.logNotificationReceived(
    type: message.data['type'] ?? 'general',
    title: message.notification?.title,
    data: message.data,
  );
  // ... باقي الكود
}

// عند الضغط على إشعار
static Future<void> onNotificationTapped(ReceivedAction action) async {
  AnalyticsHelpers.logNotificationTapped(
    type: action.payload?['type'] ?? 'general',
    action: action.buttonKeyPressed,
  );
  // ... باقي الكود
}
```

في `voip_service.dart`:

```dart
import 'package:private_4t_app/core/analytics/analytics_helpers.dart';

// مكالمة واردة
void onIncomingCall(String callId, String roomId) {
  AnalyticsHelpers.logVoipCall(
    action: 'incoming',
    callId: callId,
    roomId: roomId,
  );
}

// الرد على المكالمة
void onAnswerCall() {
  AnalyticsHelpers.logVoipCall(
    action: 'answer',
    callId: currentCallId,
  );
}

// رفض المكالمة
void onDeclineCall() {
  AnalyticsHelpers.logVoipCall(
    action: 'decline',
    callId: currentCallId,
  );
}
```

## البيانات المُرسلة

### شكل حدث (Event):

```json
{
  "deviceId": "uuid-device",
  "sessionId": "uuid-session",
  "userId": "123",
  "platform": "android",
  "appVersion": "1.1.5+66",
  "screen": "BookingOnlineScreen",
  "name": "booking_step",
  "properties": {
    "step": "grade_selected",
    "grade": "الصف الأول"
  },
  "ts": 1730800000000
}
```

### شكل سجل الشبكة (Network Log):

```json
{
  "deviceId": "uuid-device",
  "sessionId": "uuid-session",
  "userId": "123",
  "method": "POST",
  "url": "https://private-4t.com/api/v3/bookings",
  "statusCode": 200,
  "durationMs": 345,
  "requestHeaders": {
    "content-type": "application/json",
    "x-session-id": "uuid-session",
    "x-device-id": "uuid-device"
  },
  "requestBody": "{\"grade\":\"first\",\"password\":\"[BLOCKED]\"}",
  "responseHeaders": {
    "content-type": "application/json"
  },
  "responseBody": "{\"success\":true,\"token\":\"[BLOCKED]\"}",
  "error": null,
  "ts": 1730800000000
}
```

## Endpoints المطلوبة في Laravel

يجب أن تستقبل Laravel الطلبات على:

1. **POST** `/api/analytics/events`

   - Body: `{"events": [...]}`
   - Headers: `X-Session-Id`, `X-Device-Id`

2. **POST** `/api/analytics/network`
   - Body: `{"logs": [...]}`
   - Headers: `X-Session-Id`, `X-Device-Id`

## ملاحظات مهمة

1. **الأداء**: النظام مُحسّن ولا يؤثر على أداء التطبيق
2. **الخصوصية**: يتم إخفاء جميع البيانات الحساسة تلقائياً
3. **الاتصال**: يعمل حتى بدون تسجيل دخول المستخدم
4. **التخزين**: الأحداث تُخزن مؤقتاً وترسل دفعة واحدة لتحسين الأداء

## الخطوات التالية (Laravel)

- [ ] إنشاء database migrations
- [ ] إنشاء Controllers للاستقبال
- [ ] إعداد Pusher للبث المباشر
- [ ] إنشاء لوحة التحكم Dashboard
- [ ] إضافة rate limiting
- [ ] إعداد scheduled jobs للتنظيف
