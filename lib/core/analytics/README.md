# 📊 Analytics System - دليل المطور السريع

## 🎯 نظرة عامة

نظام تحليلات شامل لتتبع سلوك المستخدمين في التطبيق مع Laravel Backend.

---

## 📁 الملفات

```
lib/core/analytics/
├── analytics_models.dart              # البيانات Models
├── analytics_config.dart              # الإعدادات والمفاتيح المحمية
├── analytics_service.dart             # الخدمة الأساسية
├── analytics_network_interceptor.dart # Dio Interceptor
├── analytics_http_wrapper.dart        # HTTP Wrapper
├── analytics_navigator_observer.dart  # تتبع التنقل التلقائي
├── analytics_helpers.dart             # دوال مساعدة
└── analytics_screen_mixin.dart        # Mixin لسهولة التطبيق
```

---

## 🚀 الاستخدام السريع

### 1. إضافة Analytics لشاشة جديدة

#### الطريقة 1: باستخدام Mixin (للـ StatefulWidget)
```dart
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class _MyScreenState extends ConsumerState<MyScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'MyScreen';
  
  // تتبع التلقائي للشاشة ✅
  // logScreenView() يتم تلقائياً في initState
  
  void _onButtonPressed() {
    // تتبع الزر
    logButtonClick('submit_button', data: {
      'user_id': userId,
      'form_type': 'registration',
    });
  }
  
  void _onStepCompleted() {
    // تتبع الخطوة
    logStep('registration_step_2', data: {
      'step_name': 'Personal Info',
    });
  }
}
```

#### الطريقة 2: استخدام مباشر (للـ StatelessWidget)
```dart
import 'package:private_4t_app/core/analytics/analytics_service.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // تتبع الشاشة يدوياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logEvent(
        eventType: EventType.screenView,
        eventName: 'screen_view',
        screenName: 'MyWidget',
      );
    });
    
    return ElevatedButton(
      onPressed: () {
        // تتبع الزر
        AnalyticsService.instance.logEvent(
          eventType: EventType.buttonTap,
          eventName: 'checkout_button',
          screenName: 'MyWidget',
          data: {'cart_total': 250.0},
        );
      },
      child: Text('Checkout'),
    );
  }
}
```

---

## 📋 أنواع الأحداث

### 1. تتبع الشاشة (Screen View)
```dart
logScreenView(); // تلقائي مع Mixin
```

### 2. تتبع الزر (Button Click)
```dart
logButtonClick('button_name', data: {
  'key1': 'value1',
  'key2': 123,
});
```

### 3. تتبع الخطوة (Step)
```dart
logStep('step_name', data: {
  'step_number': 2,
  'step_title': 'Payment Info',
});
```

### 4. تتبع مخصص (Custom Event)
```dart
AnalyticsService.instance.logEvent(
  eventType: EventType.custom,
  eventName: 'video_played',
  screenName: 'CourseViewingScreen',
  data: {
    'video_id': '123',
    'duration': 300,
    'quality': 'HD',
  },
);
```

---

## 🛠️ الدوال المساعدة

في `analytics_helpers.dart`:

```dart
// تتبع الأزرار
logButtonTap(String buttonName, {Map<String, dynamic>? data})

// تتبع خطوات الحجز
logBookingStep(String stepName, {Map<String, dynamic>? data})

// تتبع الإشعارات
logNotificationReceived(String notificationType, {Map<String, dynamic>? data})

// تتبع المكالمات
logCallEvent(String callAction, {Map<String, dynamic>? data})
```

**مثال:**
```dart
import 'package:private_4t_app/core/analytics/analytics_helpers.dart';

// تتبع زر
logButtonTap('add_to_cart', data: {'product_id': '456'});

// تتبع خطوة حجز
logBookingStep('select_date', data: {'date': '2025-11-10'});

// تتبع إشعار
logNotificationReceived('message', data: {'from': 'teacher_123'});

// تتبع مكالمة
logCallEvent('call_answered', data: {'call_id': 'call_789'});
```

---

## 🔒 حماية البيانات الحساسة

### المفاتيح المحمية (Blocked Keys)

في `analytics_config.dart`:

```dart
static const List<String> blockedRequestBodyKeys = [
  'password',
  'pin', 
  'secret',
  'token',
  'api_key',
  'credit_card',
  'cvv',
  'ssn',
  'national_id',
];

static const List<String> blockedHeaderKeys = [
  'authorization',
  'cookie',
  'set-cookie',
];
```

### إضافة مفاتيح محمية جديدة

```dart
// في analytics_config.dart
static const List<String> blockedRequestBodyKeys = [
  'password',
  'otp_code',      // ← أضف هنا
  'verification_code', // ← أضف هنا
  // ... المزيد
];
```

---

## 🔌 التكاملات

### 1. Dio Interceptor (تلقائي)
يتم تسجيل جميع طلبات API من `ApiService` تلقائياً.

```dart
// في lib/core/api/api_service.dart
dio.interceptors.add(AnalyticsNetworkInterceptor());
```

### 2. HTTP Wrapper
استخدم `AnalyticsHttpWrapper` بدلاً من `http`:

```dart
// ❌ القديم
final response = await http.post(uri, body: body);

// ✅ الجديد
final response = await AnalyticsHttpWrapper.post(uri, body: body);
```

### 3. Navigator Observer (تلقائي)
يتم تسجيل التنقل بين الشاشات تلقائياً.

```dart
// في lib/core/navigation/app_router.dart
GoRouter(
  observers: [AnalyticsNavigatorObserver()],
  // ...
);
```

---

## 📊 البيانات المُرسلة

### هيكل الحدث (Event Structure)
```json
{
  "event_type": "button_tap",
  "event_name": "signin_button",
  "screen_name": "SignInScreen",
  "data": {
    "phone": "12345678",
    "has_grade": false
  },
  "timestamp": "2025-11-05T12:34:56.789Z",
  "device_id": "abc123...",
  "session_id": "xyz789...",
  "user_id": "user_456"
}
```

### هيكل Network Log
```json
{
  "url": "https://api.example.com/login",
  "method": "POST",
  "status_code": 200,
  "request_headers": {"Content-Type": "application/json"},
  "request_body": {"phone": "12345678"},
  "response_body": {"success": true, "token": "***BLOCKED***"},
  "duration_ms": 234,
  "timestamp": "2025-11-05T12:34:56.789Z"
}
```

---

## ⚙️ الإعدادات

### في `analytics_config.dart`:

```dart
class AnalyticsConfig {
  // API Endpoint
  static const String analyticsEndpoint = '/api/analytics/batch';
  
  // Batch Settings
  static const int batchSize = 20;           // عدد الأحداث في الدفعة
  static const Duration batchInterval = Duration(seconds: 10); // وقت الإرسال
  
  // Retry Settings
  static const int maxRetries = 3;           // عدد المحاولات
  static const Duration retryDelay = Duration(seconds: 2); // وقت الانتظار
  
  // Queue Settings
  static const int maxQueueSize = 1000;      // حجم قائمة الانتظار
}
```

---

## 🐛 استكشاف الأخطاء

### 1. الأحداث لا تُرسل؟
- تحقق من اتصال الإنترنت
- تحقق من `analyticsEndpoint` في `analytics_config.dart`
- تحقق من logs في console: `[Analytics]`

### 2. البيانات الحساسة تظهر؟
- أضف المفتاح إلى `blockedRequestBodyKeys` أو `blockedHeaderKeys`
- البيانات المحمية تُستبدل بـ `***BLOCKED***`

### 3. الأداء بطيء؟
- قلل `batchSize` و `batchInterval`
- زد `maxQueueSize`

---

## 📝 أمثلة عملية

### مثال 1: شاشة تسجيل الدخول
```dart
class _SignInScreenState extends ConsumerState<SignInScreen> 
    with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'SignInScreen';
  
  void _handleSignIn() async {
    // تتبع الزر
    logButtonClick('signin_button', data: {
      'phone': _phoneController.text,
      'has_grade': _selectGrade != null,
    });
    
    var result = await loginService.login(...);
    
    if (result) {
      // تتبع نجاح تسجيل الدخول
      logStep('login_success');
      context.go('/home');
    }
  }
}
```

### مثال 2: شاشة الحجز
```dart
class _BookingScreenState extends ConsumerState<BookingScreen> 
    with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'BookingScreen';
  
  void _selectDate(DateTime date) {
    // تتبع اختيار التاريخ
    logStep('date_selected', data: {
      'date': date.toIso8601String(),
    });
    setState(() => selectedDate = date);
  }
  
  void _selectSubject(Subject subject) {
    // تتبع اختيار المادة
    logStep('subject_selected', data: {
      'subject_id': subject.id,
      'subject_name': subject.name,
    });
    setState(() => selectedSubject = subject);
  }
  
  void _confirmBooking() async {
    // تتبع تأكيد الحجز
    logButtonClick('confirm_booking', data: {
      'subject_id': selectedSubject.id,
      'date': selectedDate.toIso8601String(),
      'time': selectedTime,
    });
    
    var result = await bookingService.createBooking(...);
    
    if (result.success) {
      // تتبع نجاح الحجز
      logStep('booking_confirmed', data: {
        'booking_id': result.bookingId,
      });
    }
  }
}
```

### مثال 3: شاشة السلة
```dart
class _CartScreenState extends ConsumerState<CartScreen> 
    with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'CartScreen';
  
  void _removeFromCart(String itemId) {
    // تتبع إزالة من السلة
    logButtonClick('remove_from_cart', data: {
      'item_id': itemId,
      'cart_size': cart.items.length,
    });
    
    setState(() => cart.removeItem(itemId));
  }
  
  void _applyCoupon(String code) {
    // تتبع تطبيق كوبون
    logButtonClick('apply_coupon', data: {
      'coupon_code': code,
      'cart_total': cart.total,
    });
    
    // ... logic
  }
  
  void _checkout() {
    // تتبع الدفع
    logButtonClick('checkout', data: {
      'items_count': cart.items.length,
      'total_price': cart.totalPrice,
      'has_coupon': cart.couponCode != null,
    });
    
    context.push('/payment');
  }
}
```

---

## 🎓 أفضل الممارسات

1. **استخدم أسماء واضحة للأحداث**
   ```dart
   ✅ logButtonClick('add_to_cart')
   ❌ logButtonClick('btn1')
   ```

2. **أضف بيانات مفيدة فقط**
   ```dart
   ✅ data: {'product_id': '123', 'price': 50.0}
   ❌ data: {'everything': entireObject}
   ```

3. **تتبع الخطوات المهمة فقط**
   ```dart
   ✅ logStep('payment_completed')
   ❌ logStep('button_hover') // غير مهم
   ```

4. **لا تُفرط في التتبع**
   - تتبع الأزرار المهمة فقط
   - تجنب تتبع كل حركة صغيرة

---

## 📞 الدعم

للمزيد من المعلومات، راجع:
- `ANALYTICS_COMPLETE.md` - الملخص الكامل
- `LARAVEL_ANALYTICS_IMPLEMENTATION.md` - دليل Laravel
- `ANALYTICS_IMPLEMENTATION_SUMMARY.md` - الملخص الشامل

---

**Happy Tracking! 📊✨**

