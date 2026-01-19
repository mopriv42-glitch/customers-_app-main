# Laravel Analytics Implementation Guide

## نظرة عامة

هذا الدليل يحتوي على كامل أكواد Laravel المطلوبة لاستقبال وعرض بيانات التحليلات من تطبيق Flutter.

---

## 1. Database Migrations

### المهاجرة الأولى: analytics_sessions

احفظ في: `database/migrations/2024_11_05_000001_create_analytics_sessions_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('analytics_sessions', function (Blueprint $table) {
            $table->id();
            $table->string('session_id')->unique()->index();
            $table->string('device_id')->index();
            $table->unsignedBigInteger('user_id')->nullable()->index();
            $table->string('platform', 20); // android, ios, web
            $table->string('app_version', 50);
            $table->timestamp('started_at');
            $table->timestamp('last_activity_at');
            $table->timestamps();
            
            $table->foreign('user_id')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('analytics_sessions');
    }
};
```

### المهاجرة الثانية: analytics_events

احفظ في: `database/migrations/2024_11_05_000002_create_analytics_events_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('analytics_events', function (Blueprint $table) {
            $table->id();
            $table->string('session_id')->index();
            $table->string('device_id')->index();
            $table->unsignedBigInteger('user_id')->nullable()->index();
            $table->string('platform', 20);
            $table->string('app_version', 50);
            $table->string('screen')->nullable()->index();
            $table->string('name')->index(); // event name
            $table->json('properties')->nullable();
            $table->timestamp('event_time')->index();
            $table->timestamps();
            
            $table->foreign('user_id')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('analytics_events');
    }
};
```

### المهاجرة الثالثة: analytics_network_logs

احفظ في: `database/migrations/2024_11_05_000003_create_analytics_network_logs_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('analytics_network_logs', function (Blueprint $table) {
            $table->id();
            $table->string('session_id')->index();
            $table->string('device_id')->index();
            $table->unsignedBigInteger('user_id')->nullable()->index();
            $table->string('method', 10); // GET, POST, PUT, DELETE
            $table->text('url');
            $table->integer('status_code')->nullable()->index();
            $table->integer('duration_ms');
            $table->json('request_headers')->nullable();
            $table->longText('request_body')->nullable();
            $table->json('response_headers')->nullable();
            $table->longText('response_body')->nullable();
            $table->text('error')->nullable();
            $table->timestamp('request_time')->index();
            $table->timestamps();
            
            $table->foreign('user_id')->references('id')->on('users')->onDelete('set null');
            
            // Index للبحث السريع
            $table->index(['status_code', 'request_time']);
            $table->index(['user_id', 'request_time']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('analytics_network_logs');
    }
};
```

---

## 2. Configuration File

احفظ في: `config/analytics.php`

```php
<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Analytics Configuration
    |--------------------------------------------------------------------------
    */

    // Maximum body size in bytes (100KB)
    'max_body_bytes' => 100 * 1024,

    // Data retention period (days)
    'retention_days' => 30,

    // Enable/disable real-time broadcasting
    'enable_broadcasting' => env('ANALYTICS_BROADCASTING', true),

    // Pusher channel name for analytics
    'pusher_channel' => 'private-analytics',

    // Blocked keys for request data
    'blocked_request_keys' => [
        'password',
        'password_confirmation',
        'old_password',
        'new_password',
        'pin',
        'cvv',
        'card_number',
        'card_cvv',
        'ssn',
        'social_security',
        'credit_card',
        'api_key',
        'secret',
        'private_key',
        'access_token',
        'refresh_token',
    ],

    // Blocked keys for response data
    'blocked_response_keys' => [
        'password',
        'token',
        'access_token',
        'refresh_token',
        'api_key',
        'secret',
        'private_key',
    ],

    // Rate limiting (requests per minute)
    'rate_limit' => [
        'events' => 120,
        'network_logs' => 120,
    ],
];
```

---

## 3. Models

### AnalyticsSession Model

احفظ في: `app/Models/AnalyticsSession.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AnalyticsSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'session_id',
        'device_id',
        'user_id',
        'platform',
        'app_version',
        'started_at',
        'last_activity_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'last_activity_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function events(): HasMany
    {
        return $this->hasMany(AnalyticsEvent::class, 'session_id', 'session_id');
    }

    public function networkLogs(): HasMany
    {
        return $this->hasMany(AnalyticsNetworkLog::class, 'session_id', 'session_id');
    }
}
```

### AnalyticsEvent Model

احفظ في: `app/Models/AnalyticsEvent.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AnalyticsEvent extends Model
{
    use HasFactory;

    protected $fillable = [
        'session_id',
        'device_id',
        'user_id',
        'platform',
        'app_version',
        'screen',
        'name',
        'properties',
        'event_time',
    ];

    protected $casts = [
        'properties' => 'array',
        'event_time' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function session(): BelongsTo
    {
        return $this->belongsTo(AnalyticsSession::class, 'session_id', 'session_id');
    }
}
```

### AnalyticsNetworkLog Model

احفظ في: `app/Models/AnalyticsNetworkLog.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AnalyticsNetworkLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'session_id',
        'device_id',
        'user_id',
        'method',
        'url',
        'status_code',
        'duration_ms',
        'request_headers',
        'request_body',
        'response_headers',
        'response_body',
        'error',
        'request_time',
    ];

    protected $casts = [
        'request_headers' => 'array',
        'response_headers' => 'array',
        'request_time' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function session(): BelongsTo
    {
        return $this->belongsTo(AnalyticsSession::class, 'session_id', 'session_id');
    }

    public function getIsSuccessAttribute(): bool
    {
        return $this->status_code >= 200 && $this->status_code < 300;
    }

    public function getIsErrorAttribute(): bool
    {
        return $this->status_code >= 400 || !is_null($this->error);
    }
}
```

---

## 4. Services

احفظ في: `app/Services/AnalyticsSanitizerService.php`

```php
<?php

namespace App\Services;

class AnalyticsSanitizerService
{
    protected array $blockedRequestKeys;
    protected array $blockedResponseKeys;
    protected int $maxBodyBytes;

    public function __construct()
    {
        $this->blockedRequestKeys = config('analytics.blocked_request_keys', []);
        $this->blockedResponseKeys = config('analytics.blocked_response_keys', []);
        $this->maxBodyBytes = config('analytics.max_body_bytes', 100 * 1024);
    }

    /**
     * Sanitize request data
     */
    public function sanitizeRequest(array $data): array
    {
        return [
            'headers' => $this->filterHeaders($data['headers'] ?? [], $this->blockedRequestKeys),
            'body' => $this->filterBody($data['body'] ?? null, $this->blockedRequestKeys),
        ];
    }

    /**
     * Sanitize response data
     */
    public function sanitizeResponse(array $data): array
    {
        return [
            'headers' => $this->filterHeaders($data['headers'] ?? [], $this->blockedResponseKeys),
            'body' => $this->filterBody($data['body'] ?? null, $this->blockedResponseKeys),
        ];
    }

    /**
     * Filter headers by removing blocked keys
     */
    protected function filterHeaders(array $headers, array $blockedKeys): array
    {
        $filtered = [];
        
        foreach ($headers as $key => $value) {
            if ($this->shouldBlockKey($key, $blockedKeys)) {
                $filtered[$key] = '[BLOCKED]';
            } else {
                $filtered[$key] = $value;
            }
        }
        
        return $filtered;
    }

    /**
     * Filter body by removing blocked keys
     */
    protected function filterBody($body, array $blockedKeys): ?string
    {
        if (is_null($body)) {
            return null;
        }

        // If body is JSON string, parse it
        if (is_string($body)) {
            $decoded = json_decode($body, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                $filtered = $this->filterArray($decoded, $blockedKeys);
                $body = json_encode($filtered, JSON_UNESCAPED_UNICODE);
            }
        }

        // Truncate if too large
        return $this->truncate($body);
    }

    /**
     * Recursively filter array by blocked keys
     */
    protected function filterArray(array $data, array $blockedKeys): array
    {
        $filtered = [];
        
        foreach ($data as $key => $value) {
            if ($this->shouldBlockKey($key, $blockedKeys)) {
                $filtered[$key] = '[BLOCKED]';
            } elseif (is_array($value)) {
                $filtered[$key] = $this->filterArray($value, $blockedKeys);
            } else {
                $filtered[$key] = $value;
            }
        }
        
        return $filtered;
    }

    /**
     * Check if key should be blocked
     */
    protected function shouldBlockKey(string $key, array $blockedKeys): bool
    {
        $lowerKey = strtolower($key);
        
        foreach ($blockedKeys as $blocked) {
            $lowerBlocked = strtolower($blocked);
            
            // Exact match
            if ($lowerKey === $lowerBlocked) {
                return true;
            }
            
            // Contains match
            if (str_contains($lowerKey, $lowerBlocked)) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * Truncate string if exceeds max bytes
     */
    protected function truncate(?string $data): ?string
    {
        if (is_null($data)) {
            return null;
        }

        if (strlen($data) > $this->maxBodyBytes) {
            return substr($data, 0, $this->maxBodyBytes) . '... [TRUNCATED]';
        }
        
        return $data;
    }
}
```

سأكمل في الرسالة التالية مع Controllers والـ Broadcasting والـ Dashboard...


