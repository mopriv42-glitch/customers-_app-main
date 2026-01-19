# Laravel Analytics Implementation - Part 3 (Final)

## 7. Routes

### API Routes

أضف في: `routes/api.php`

```php
<?php

use App\Http\Controllers\Api\AnalyticsIngestController;
use Illuminate\Support\Facades\Route;

// Analytics ingestion endpoints (no auth required - uses device/session IDs)
Route::prefix('analytics')->group(function () {
    Route::post('/events', [AnalyticsIngestController::class, 'ingestEvents'])
        ->middleware('throttle:analytics_events');
    
    Route::post('/network', [AnalyticsIngestController::class, 'ingestNetworkLogs'])
        ->middleware('throttle:analytics_network');
});
```

### Web/Admin Routes

أضف في: `routes/web.php` أو `routes/admin.php`

```php
<?php

use App\Http\Controllers\Admin\AnalyticsDashboardController;
use Illuminate\Support\Facades\Route;

// Analytics Dashboard (admin only)
Route::middleware(['auth', 'admin'])->prefix('admin/analytics')->group(function () {
    Route::get('/', [AnalyticsDashboardController::class, 'index'])->name('admin.analytics.dashboard');
    Route::get('/live', [AnalyticsDashboardController::class, 'live'])->name('admin.analytics.live');
    Route::get('/stats', [AnalyticsDashboardController::class, 'stats'])->name('admin.analytics.stats');
    Route::get('/session/{sessionId}', [AnalyticsDashboardController::class, 'sessionDetails'])
        ->name('admin.analytics.session');
});
```

### Broadcasting Channels

أضف في: `routes/channels.php`

```php
<?php

use Illuminate\Support\Facades\Broadcast;

// Analytics channel (admin only)
Broadcast::channel(config('analytics.pusher_channel'), function ($user) {
    // Only admins can subscribe to analytics channel
    return $user->is_admin === true;
});
```

---

## 8. Middleware (Optional)

### LogIncomingApiMiddleware

احفظ في: `app/Http/Middleware/LogIncomingApiMiddleware.php`

```php
<?php

namespace App\Http\Middleware;

use App\Models\AnalyticsNetworkLog;
use Carbon\Carbon;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class LogIncomingApiMiddleware
{
    /**
     * Handle an incoming request - log it as analytics
     */
    public function handle(Request $request, Closure $next): Response
    {
        $startTime = microtime(true);
        
        // Process request
        $response = $next($request);
        
        // Calculate duration
        $duration = (microtime(true) - $startTime) * 1000; // in milliseconds

        // Log to analytics (in background to not slow down response)
        $this->logToAnalytics($request, $response, $duration);

        return $response;
    }

    protected function logToAnalytics(Request $request, Response $response, float $duration): void
    {
        try {
            // Get session info from headers
            $sessionId = $request->header('X-Session-Id');
            $deviceId = $request->header('X-Device-Id');
            
            if (!$sessionId || !$deviceId) {
                return; // Skip if no analytics headers
            }

            AnalyticsNetworkLog::create([
                'session_id' => $sessionId,
                'device_id' => $deviceId,
                'user_id' => Auth::id(),
                'method' => $request->method(),
                'url' => $request->fullUrl(),
                'status_code' => $response->getStatusCode(),
                'duration_ms' => (int) $duration,
                'request_headers' => $this->sanitizeHeaders($request->headers->all()),
                'request_body' => $this->sanitizeBody($request->all()),
                'response_headers' => $this->sanitizeHeaders($response->headers->all()),
                'response_body' => $this->sanitizeBody($response->getContent()),
                'error' => $response->getStatusCode() >= 400 ? $response->getContent() : null,
                'request_time' => Carbon::now(),
            ]);
        } catch (\Exception $e) {
            // Silently fail - don't break the actual request
            \Log::error('Failed to log API request to analytics', [
                'error' => $e->getMessage(),
            ]);
        }
    }

    protected function sanitizeHeaders(array $headers): array
    {
        // Remove sensitive headers
        $blocked = ['authorization', 'cookie', 'set-cookie'];
        
        return collect($headers)
            ->reject(fn($value, $key) => in_array(strtolower($key), $blocked))
            ->toArray();
    }

    protected function sanitizeBody($body): ?string
    {
        if (is_string($body)) {
            $decoded = json_decode($body, true);
            if (json_last_error() === JSON_ERROR_NONE) {
                $body = $decoded;
            }
        }

        if (is_array($body)) {
            // Remove sensitive fields
            $blocked = ['password', 'token', 'api_key', 'secret'];
            $body = collect($body)
                ->reject(fn($value, $key) => in_array(strtolower($key), $blocked))
                ->toArray();
            
            return json_encode($body);
        }

        return null;
    }
}
```

لتفعيل الـ Middleware، أضف في `app/Http/Kernel.php`:

```php
protected $middlewareGroups = [
    'api' => [
        // ... existing middleware
        \App\Http\Middleware\LogIncomingApiMiddleware::class, // أضف هنا
    ],
];
```

---

## 9. Rate Limiting

أضف في: `app/Providers/RouteServiceProvider.php` (أو `bootstrap/app.php` في Laravel 11)

```php
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;

/**
 * Configure rate limiters
 */
protected function configureRateLimiting(): void
{
    // Analytics events rate limiter
    RateLimiter::for('analytics_events', function (Request $request) {
        return Limit::perMinute(config('analytics.rate_limit.events', 120))
            ->by($request->header('X-Device-Id') ?? $request->ip());
    });

    // Analytics network logs rate limiter
    RateLimiter::for('analytics_network', function (Request $request) {
        return Limit::perMinute(config('analytics.rate_limit.network_logs', 120))
            ->by($request->header('X-Device-Id') ?? $request->ip());
    });
}
```

---

## 10. Scheduled Jobs (Pruning)

احفظ في: `app/Console/Commands/PruneAnalyticsData.php`

```php
<?php

namespace App\Console\Commands;

use App\Models\AnalyticsEvent;
use App\Models\AnalyticsNetworkLog;
use App\Models\AnalyticsSession;
use Carbon\Carbon;
use Illuminate\Console\Command;

class PruneAnalyticsData extends Command
{
    protected $signature = 'analytics:prune {--days=30 : Number of days to retain}';
    protected $description = 'Prune old analytics data';

    public function handle(): int
    {
        $days = (int) $this->option('days') ?: config('analytics.retention_days', 30);
        $cutoffDate = Carbon::now()->subDays($days);

        $this->info("Pruning analytics data older than {$days} days ({$cutoffDate->toDateString()})...");

        // Delete old events
        $eventsDeleted = AnalyticsEvent::where('event_time', '<', $cutoffDate)->delete();
        $this->info("Deleted {$eventsDeleted} events");

        // Delete old network logs
        $logsDeleted = AnalyticsNetworkLog::where('request_time', '<', $cutoffDate)->delete();
        $this->info("Deleted {$logsDeleted} network logs");

        // Delete orphaned sessions
        $sessionsDeleted = AnalyticsSession::where('last_activity_at', '<', $cutoffDate)->delete();
        $this->info("Deleted {$sessionsDeleted} sessions");

        $this->info('Analytics pruning completed successfully!');

        return self::SUCCESS;
    }
}
```

جدولة الأمر في: `app/Console/Kernel.php`

```php
protected function schedule(Schedule $schedule): void
{
    // Run analytics pruning daily at 2 AM
    $schedule->command('analytics:prune')->daily()->at('02:00');
}
```

---

## 11. Dashboard View (Blade)

احفظ في: `resources/views/admin/analytics/dashboard.blade.php`

```blade
@extends('layouts.admin')

@section('title', 'Analytics Dashboard')

@section('content')
<div class="container-fluid" x-data="analyticsApp()">
    <div class="row mb-4">
        <div class="col-12">
            <h1 class="h3">تحليلات سلوك المستخدمين - مباشر</h1>
        </div>
    </div>

    <!-- Stats Cards -->
    <div class="row mb-4">
        <div class="col-md-3">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">الجلسات النشطة</h5>
                    <h2 class="mb-0" x-text="stats.total_sessions">0</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">المستخدمون</h5>
                    <h2 class="mb-0" x-text="stats.total_users">0</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">إجمالي الأحداث</h5>
                    <h2 class="mb-0" x-text="stats.total_events">0</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card bg-danger text-white">
                <div class="card-body">
                    <h5 class="card-title">أخطاء API</h5>
                    <h2 class="mb-0" x-text="stats.api_errors">0</h2>
                </div>
            </div>
        </div>
    </div>

    <!-- Filters -->
    <div class="card mb-4">
        <div class="card-body">
            <div class="row">
                <div class="col-md-3">
                    <input type="text" class="form-control" placeholder="بحث..." x-model="filters.search">
                </div>
                <div class="col-md-2">
                    <select class="form-control" x-model="filters.eventType">
                        <option value="">كل الأحداث</option>
                        <option value="screen_view">عرض شاشة</option>
                        <option value="button_tap">ضغط زر</option>
                        <option value="booking_step">خطوة حجز</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <select class="form-control" x-model="filters.statusCode">
                        <option value="">كل الحالات</option>
                        <option value="200">200 - نجاح</option>
                        <option value="400">400 - خطأ</option>
                        <option value="500">500 - خطأ خادم</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <button class="btn btn-primary" @click="applyFilters">تطبيق</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Live Feed -->
    <div class="row">
        <!-- Events Column -->
        <div class="col-md-6">
            <div class="card">
                <div class="card-header">
                    <h5>الأحداث المباشرة</h5>
                </div>
                <div class="card-body" style="max-height: 600px; overflow-y: auto;">
                    <template x-for="event in events" :key="event.id">
                        <div class="alert alert-info mb-2">
                            <strong x-text="event.name"></strong>
                            <small class="text-muted" x-text="event.event_time"></small>
                            <br>
                            <small>Screen: <span x-text="event.screen"></span></small>
                            <br>
                            <small>User: <span x-text="event.user_name || 'Guest'"></span></small>
                            <template x-if="event.properties">
                                <pre class="mt-2" x-text="JSON.stringify(event.properties, null, 2)"></pre>
                            </template>
                        </div>
                    </template>
                </div>
            </div>
        </div>

        <!-- Network Logs Column -->
        <div class="col-md-6">
            <div class="card">
                <div class="card-header">
                    <h5>طلبات API المباشرة</h5>
                </div>
                <div class="card-body" style="max-height: 600px; overflow-y: auto;">
                    <template x-for="log in networkLogs" :key="log.id">
                        <div class="alert mb-2" :class="log.is_error ? 'alert-danger' : 'alert-success'">
                            <strong x-text="log.method + ' ' + log.status_code"></strong>
                            <small class="text-muted" x-text="log.request_time"></small>
                            <br>
                            <small x-text="log.url"></small>
                            <br>
                            <small>Duration: <span x-text="log.duration_ms + 'ms'"></span></small>
                            <template x-if="log.error">
                                <div class="mt-2 text-danger" x-text="log.error"></div>
                            </template>
                        </div>
                    </template>
                </div>
            </div>
        </div>
    </div>
</div>

@push('scripts')
<script src="https://js.pusher.com/8.2.0/pusher.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
<script>
function analyticsApp() {
    return {
        events: [],
        networkLogs: [],
        stats: {
            total_sessions: 0,
            total_users: 0,
            total_events: 0,
            api_errors: 0,
        },
        filters: {
            search: '',
            eventType: '',
            statusCode: '',
        },

        init() {
            this.loadInitialData();
            this.setupPusher();
            this.loadStats();
        },

        async loadInitialData() {
            try {
                const response = await fetch('{{ route('admin.analytics.live') }}');
                const data = await response.json();
                this.events = data.events;
                this.networkLogs = data.network_logs;
            } catch (error) {
                console.error('Failed to load initial data:', error);
            }
        },

        async loadStats() {
            try {
                const response = await fetch('{{ route('admin.analytics.stats') }}?period=24h');
                const data = await response.json();
                this.stats = data;
            } catch (error) {
                console.error('Failed to load stats:', error);
            }
        },

        setupPusher() {
            const pusher = new Pusher('{{ config('broadcasting.connections.pusher.key') }}', {
                cluster: '{{ config('broadcasting.connections.pusher.options.cluster') }}',
                encrypted: true,
                authEndpoint: '/broadcasting/auth',
            });

            const channel = pusher.subscribe('{{ config('analytics.pusher_channel') }}');

            channel.bind('event.logged', (data) => {
                this.events.unshift(data.data);
                if (this.events.length > 50) {
                    this.events.pop();
                }
                this.loadStats();
            });

            channel.bind('network.logged', (data) => {
                this.networkLogs.unshift(data.data);
                if (this.networkLogs.length > 50) {
                    this.networkLogs.pop();
                }
                this.loadStats();
            });
        },

        async applyFilters() {
            const params = new URLSearchParams(this.filters).toString();
            const response = await fetch('{{ route('admin.analytics.live') }}?' + params);
            const data = await response.json();
            this.events = data.events;
            this.networkLogs = data.network_logs;
        },
    };
}
</script>
@endpush
@endsection
```

---

## 12. Environment Variables

أضف في `.env`:

```env
# Pusher (already configured)
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=your_app_id
PUSHER_APP_KEY=your_key
PUSHER_APP_SECRET=your_secret
PUSHER_APP_CLUSTER=mt1

# Analytics
ANALYTICS_BROADCASTING=true
```

---

## 13. Deployment Steps

### 1. تنفيذ المهاجرات
```bash
php artisan migrate
```

### 2. نشر الإعدادات
```bash
php artisan config:cache
php artisan route:cache
```

### 3. إعداد Queue Worker (للبث)
```bash
php artisan queue:work --queue=default
```

### 4. اختبار Pusher
```bash
php artisan tinker
>>> broadcast(new \App\Events\AnalyticsEventLogged(\App\Models\AnalyticsEvent::first()));
```

---

## 14. الملخص

✅ **تم تطبيق:**
1. ✅ Database migrations (3 جداول)
2. ✅ Models (3 نماذج)
3. ✅ Controllers (Ingest + Dashboard)
4. ✅ Broadcasting Events (Pusher)
5. ✅ Routes (API + Web)
6. ✅ Middleware (اختياري للتسجيل التلقائي)
7. ✅ Rate Limiting
8. ✅ Scheduled Pruning
9. ✅ Dashboard View
10. ✅ Sanitizer Service

**الخطوات المتبقية عليك:**
1. نسخ الملفات إلى مشروع Laravel
2. تنفيذ `php artisan migrate`
3. إعداد Pusher credentials
4. الوصول إلى `/admin/analytics` للوحة التحكم

**النتيجة النهائية:**
- تطبيق Flutter يرسل كل الأحداث والـ API requests
- Laravel يستقبل ويخزن البيانات
- Pusher يبث التحديثات فوراً
- لوحة تحكم تعرض كل شيء مباشرة!

🎉 **اكتمل التنفيذ!**

