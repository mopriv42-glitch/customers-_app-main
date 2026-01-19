# Laravel Analytics Implementation - Part 2

## 5. Controllers

### AnalyticsIngestController

احفظ في: `app/Http/Controllers/Api/AnalyticsIngestController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Events\AnalyticsEventLogged;
use App\Events\AnalyticsNetworkLogRecorded;
use App\Http\Controllers\Controller;
use App\Models\AnalyticsEvent;
use App\Models\AnalyticsNetworkLog;
use App\Models\AnalyticsSession;
use App\Services\AnalyticsSanitizerService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class AnalyticsIngestController extends Controller
{
    protected AnalyticsSanitizerService $sanitizer;

    public function __construct(AnalyticsSanitizerService $sanitizer)
    {
        $this->sanitizer = $sanitizer;
    }

    /**
     * Ingest analytics events
     *
     * POST /api/analytics/events
     */
    public function ingestEvents(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'events' => 'required|array|min:1|max:50',
            'events.*.deviceId' => 'required|string',
            'events.*.sessionId' => 'required|string',
            'events.*.userId' => 'nullable|string',
            'events.*.platform' => 'required|string',
            'events.*.appVersion' => 'required|string',
            'events.*.screen' => 'nullable|string',
            'events.*.name' => 'required|string',
            'events.*.properties' => 'nullable|array',
            'events.*.ts' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            DB::beginTransaction();

            $events = collect($request->input('events'));
            $inserted = [];

            foreach ($events as $eventData) {
                // Update or create session
                $this->updateSession(
                    $eventData['sessionId'],
                    $eventData['deviceId'],
                    $eventData['userId'] ?? null,
                    $eventData['platform'],
                    $eventData['appVersion'],
                    Carbon::createFromTimestampMs($eventData['ts'])
                );

                // Create event
                $event = AnalyticsEvent::create([
                    'session_id' => $eventData['sessionId'],
                    'device_id' => $eventData['deviceId'],
                    'user_id' => $eventData['userId'] ?? null,
                    'platform' => $eventData['platform'],
                    'app_version' => $eventData['appVersion'],
                    'screen' => $eventData['screen'] ?? null,
                    'name' => $eventData['name'],
                    'properties' => $eventData['properties'] ?? null,
                    'event_time' => Carbon::createFromTimestampMs($eventData['ts']),
                ]);

                $inserted[] = $event;

                // Broadcast event if enabled
                if (config('analytics.enable_broadcasting')) {
                    broadcast(new AnalyticsEventLogged($event))->toOthers();
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Events ingested successfully',
                'count' => count($inserted),
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Analytics event ingestion failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to ingest events',
            ], 500);
        }
    }

    /**
     * Ingest network logs
     *
     * POST /api/analytics/network
     */
    public function ingestNetworkLogs(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'logs' => 'required|array|min:1|max:50',
            'logs.*.deviceId' => 'required|string',
            'logs.*.sessionId' => 'required|string',
            'logs.*.userId' => 'nullable|string',
            'logs.*.method' => 'required|string',
            'logs.*.url' => 'required|string',
            'logs.*.statusCode' => 'nullable|integer',
            'logs.*.durationMs' => 'required|integer',
            'logs.*.requestHeaders' => 'nullable|array',
            'logs.*.requestBody' => 'nullable',
            'logs.*.responseHeaders' => 'nullable|array',
            'logs.*.responseBody' => 'nullable',
            'logs.*.error' => 'nullable|string',
            'logs.*.ts' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            DB::beginTransaction();

            $logs = collect($request->input('logs'));
            $inserted = [];

            foreach ($logs as $logData) {
                // Sanitize sensitive data (already done in Flutter, but double-check)
                $sanitizedRequest = $this->sanitizer->sanitizeRequest([
                    'headers' => $logData['requestHeaders'] ?? [],
                    'body' => $logData['requestBody'] ?? null,
                ]);

                $sanitizedResponse = $this->sanitizer->sanitizeResponse([
                    'headers' => $logData['responseHeaders'] ?? [],
                    'body' => $logData['responseBody'] ?? null,
                ]);

                // Create network log
                $log = AnalyticsNetworkLog::create([
                    'session_id' => $logData['sessionId'],
                    'device_id' => $logData['deviceId'],
                    'user_id' => $logData['userId'] ?? null,
                    'method' => $logData['method'],
                    'url' => $logData['url'],
                    'status_code' => $logData['statusCode'] ?? null,
                    'duration_ms' => $logData['durationMs'],
                    'request_headers' => $sanitizedRequest['headers'],
                    'request_body' => $sanitizedRequest['body'],
                    'response_headers' => $sanitizedResponse['headers'],
                    'response_body' => $sanitizedResponse['body'],
                    'error' => $logData['error'] ?? null,
                    'request_time' => Carbon::createFromTimestampMs($logData['ts']),
                ]);

                $inserted[] = $log;

                // Broadcast if enabled and is error
                if (config('analytics.enable_broadcasting') && $log->is_error) {
                    broadcast(new AnalyticsNetworkLogRecorded($log))->toOthers();
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Network logs ingested successfully',
                'count' => count($inserted),
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Analytics network log ingestion failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to ingest network logs',
            ], 500);
        }
    }

    /**
     * Update or create session
     */
    protected function updateSession(
        string $sessionId,
        string $deviceId,
        ?string $userId,
        string $platform,
        string $appVersion,
        Carbon $timestamp
    ): void {
        AnalyticsSession::updateOrCreate(
            ['session_id' => $sessionId],
            [
                'device_id' => $deviceId,
                'user_id' => $userId,
                'platform' => $platform,
                'app_version' => $appVersion,
                'started_at' => $timestamp,
                'last_activity_at' => $timestamp,
            ]
        );
    }
}
```

### AnalyticsDashboardController

احفظ في: `app/Http/Controllers/Admin/AnalyticsDashboardController.php`

```php
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AnalyticsEvent;
use App\Models\AnalyticsNetworkLog;
use App\Models\AnalyticsSession;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnalyticsDashboardController extends Controller
{
    /**
     * Show analytics dashboard
     */
    public function index()
    {
        return view('admin.analytics.dashboard');
    }

    /**
     * Get realtime analytics data (for live view)
     */
    public function live(Request $request)
    {
        $limit = $request->input('limit', 50);
        $userId = $request->input('user_id');
        $sessionId = $request->input('session_id');
        $screen = $request->input('screen');
        $eventType = $request->input('event_type');
        $statusCode = $request->input('status_code');
        $search = $request->input('search');

        // Get events
        $eventsQuery = AnalyticsEvent::with('user')
            ->orderBy('event_time', 'desc');

        if ($userId) {
            $eventsQuery->where('user_id', $userId);
        }

        if ($sessionId) {
            $eventsQuery->where('session_id', $sessionId);
        }

        if ($screen) {
            $eventsQuery->where('screen', $screen);
        }

        if ($eventType) {
            $eventsQuery->where('name', $eventType);
        }

        if ($search) {
            $eventsQuery->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('screen', 'like', "%{$search}%")
                  ->orWhereRaw("JSON_SEARCH(properties, 'one', ?) IS NOT NULL", ["%{$search}%"]);
            });
        }

        $events = $eventsQuery->limit($limit)->get();

        // Get network logs
        $logsQuery = AnalyticsNetworkLog::with('user')
            ->orderBy('request_time', 'desc');

        if ($userId) {
            $logsQuery->where('user_id', $userId);
        }

        if ($sessionId) {
            $logsQuery->where('session_id', $sessionId);
        }

        if ($statusCode) {
            $logsQuery->where('status_code', $statusCode);
        }

        if ($search) {
            $logsQuery->where(function ($q) use ($search) {
                $q->where('url', 'like', "%{$search}%")
                  ->orWhere('error', 'like', "%{$search}%");
            });
        }

        $networkLogs = $logsQuery->limit($limit)->get();

        return response()->json([
            'events' => $events,
            'network_logs' => $networkLogs,
        ]);
    }

    /**
     * Get analytics statistics
     */
    public function stats(Request $request)
    {
        $period = $request->input('period', '24h'); // 24h, 7d, 30d

        $startDate = match($period) {
            '24h' => Carbon::now()->subHours(24),
            '7d' => Carbon::now()->subDays(7),
            '30d' => Carbon::now()->subDays(30),
            default => Carbon::now()->subHours(24),
        };

        return response()->json([
            'total_sessions' => AnalyticsSession::where('started_at', '>=', $startDate)->count(),
            'total_users' => AnalyticsSession::where('started_at', '>=', $startDate)
                ->whereNotNull('user_id')
                ->distinct('user_id')
                ->count(),
            'total_events' => AnalyticsEvent::where('event_time', '>=', $startDate)->count(),
            'total_api_calls' => AnalyticsNetworkLog::where('request_time', '>=', $startDate)->count(),
            'api_errors' => AnalyticsNetworkLog::where('request_time', '>=', $startDate)
                ->where(function ($q) {
                    $q->where('status_code', '>=', 400)
                      ->orWhereNotNull('error');
                })
                ->count(),
            'avg_response_time' => AnalyticsNetworkLog::where('request_time', '>=', $startDate)
                ->avg('duration_ms'),
            'top_screens' => AnalyticsEvent::where('event_time', '>=', $startDate)
                ->whereNotNull('screen')
                ->select('screen', DB::raw('count(*) as count'))
                ->groupBy('screen')
                ->orderBy('count', 'desc')
                ->limit(10)
                ->get(),
            'top_events' => AnalyticsEvent::where('event_time', '>=', $startDate)
                ->select('name', DB::raw('count(*) as count'))
                ->groupBy('name')
                ->orderBy('count', 'desc')
                ->limit(10)
                ->get(),
        ]);
    }

    /**
     * Get session details
     */
    public function sessionDetails($sessionId)
    {
        $session = AnalyticsSession::with('user')
            ->where('session_id', $sessionId)
            ->firstOrFail();

        $events = AnalyticsEvent::where('session_id', $sessionId)
            ->orderBy('event_time')
            ->get();

        $networkLogs = AnalyticsNetworkLog::where('session_id', $sessionId)
            ->orderBy('request_time')
            ->get();

        return response()->json([
            'session' => $session,
            'events' => $events,
            'network_logs' => $networkLogs,
        ]);
    }
}
```

---

## 6. Broadcasting Events

### AnalyticsEventLogged Event

احفظ في: `app/Events/AnalyticsEventLogged.php`

```php
<?php

namespace App\Events;

use App\Models\AnalyticsEvent;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class AnalyticsEventLogged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public AnalyticsEvent $event;

    public function __construct(AnalyticsEvent $event)
    {
        $this->event = $event;
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel(config('analytics.pusher_channel')),
        ];
    }

    public function broadcastAs(): string
    {
        return 'event.logged';
    }

    public function broadcastWith(): array
    {
        return [
            'type' => 'event',
            'data' => [
                'id' => $this->event->id,
                'session_id' => $this->event->session_id,
                'user_id' => $this->event->user_id,
                'user_name' => $this->event->user?->name,
                'platform' => $this->event->platform,
                'screen' => $this->event->screen,
                'name' => $this->event->name,
                'properties' => $this->event->properties,
                'event_time' => $this->event->event_time->toIso8601String(),
            ],
        ];
    }
}
```

### AnalyticsNetworkLogRecorded Event

احفظ في: `app/Events/AnalyticsNetworkLogRecorded.php`

```php
<?php

namespace App\Events;

use App\Models\AnalyticsNetworkLog;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class AnalyticsNetworkLogRecorded implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public AnalyticsNetworkLog $log;

    public function __construct(AnalyticsNetworkLog $log)
    {
        $this->log = $log;
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel(config('analytics.pusher_channel')),
        ];
    }

    public function broadcastAs(): string
    {
        return 'network.logged';
    }

    public function broadcastWith(): array
    {
        return [
            'type' => 'network_log',
            'data' => [
                'id' => $this->log->id,
                'session_id' => $this->log->session_id,
                'user_id' => $this->log->user_id,
                'user_name' => $this->log->user?->name,
                'method' => $this->log->method,
                'url' => $this->log->url,
                'status_code' => $this->log->status_code,
                'duration_ms' => $this->log->duration_ms,
                'is_error' => $this->log->is_error,
                'error' => $this->log->error,
                'request_time' => $this->log->request_time->toIso8601String(),
            ],
        ];
    }
}
```

سأكمل في الجزء الثالث مع Routes و Middleware و Dashboard View...


