# 🚀 Quick Start - Analytics System

## للبدء السريع

### 1️⃣ Flutter Setup (تم ✅)

النظام جاهز للعمل! فقط:

```bash
# 1. تحديث التبعيات
flutter pub get

# 2. تشغيل التطبيق
flutter run
```

---

### 2️⃣ Laravel Setup (مطلوب)

#### الخطوة 1: Database Migrations

انسخ والصق هذا الكود في Laravel:

```bash
# إنشاء الـ migrations
php artisan make:migration create_analytics_events_table
php artisan make:migration create_analytics_network_logs_table
php artisan make:migration create_analytics_sessions_table
```

**راجع `LARAVEL_ANALYTICS_IMPLEMENTATION.md` لمحتوى كل migration**

#### الخطوة 2: تشغيل Migrations

```bash
php artisan migrate
```

#### الخطوة 3: Models & Controller

```bash
php artisan make:model AnalyticsEvent
php artisan make:model AnalyticsNetworkLog
php artisan make:model AnalyticsSession
php artisan make:controller AnalyticsController
```

#### الخطوة 4: Routes

في `routes/api.php`:

```php
use App\Http\Controllers\AnalyticsController;

Route::prefix('analytics')->group(function () {
    Route::post('/batch', [AnalyticsController::class, 'storeBatch']);
    Route::post('/events', [AnalyticsController::class, 'storeEvent']);
    Route::get('/dashboard', [AnalyticsController::class, 'dashboard']);
});
```

#### الخطوة 5: Pusher Setup

```bash
composer require pusher/pusher-php-server
```

في `.env`:

```env
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=your_app_id
PUSHER_APP_KEY=your_app_key
PUSHER_APP_SECRET=your_app_secret
PUSHER_APP_CLUSTER=your_cluster
```

---

### 3️⃣ اختبار النظام

#### في Flutter:

```dart
// في أي شاشة
import 'package:private_4t_app/core/analytics/analytics_service.dart';

// تسجيل حدث
AnalyticsService.instance.logEvent(
  eventType: EventType.buttonTap,
  eventName: 'test_button',
  screenName: 'TestScreen',
  data: {'test': 'success'},
);
```

#### في Laravel:

افتح Dashboard:
```
http://your-domain.com/api/analytics/dashboard
```

---

## 📖 التوثيق الكامل

- `ANALYTICS_COMPLETE.md` - الملخص الكامل
- `LARAVEL_ANALYTICS_IMPLEMENTATION.md` - دليل Laravel المفصل
- `lib/core/analytics/README.md` - دليل المطور

---

## ✅ Checklist

### Flutter ✅
- [x] Analytics System مثبّت
- [x] جميع الشاشات متتبعة (64 شاشة)
- [x] Pusher مفعّل
- [x] API Interceptors جاهزة

### Laravel ⚠️
- [ ] Migrations تم إنشاؤها
- [ ] Models تم إنشاؤها
- [ ] Controller تم إنشاؤه
- [ ] Routes تم إضافتها
- [ ] Pusher تم تهيئته
- [ ] Dashboard تم إنشاؤه

---

**ابدأ الآن! 🚀**

