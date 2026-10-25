<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class YoutubeVideoService
{
    /**
     * Get YouTube video duration in seconds using YouTube Data API v3.
     */
    public function getDurationInSeconds(string $url)
    {
        $videoId = $this->extractVideoId($url);

        if (!$videoId) {
            Log::warning("Could not extract video ID from URL: {$url}");
            return null;
        }

        $key = DB::table('tbl_settings')
            ->where('type', 'youtube_api_key')
            ->value('message');

        if (blank($key)) {
            Log::warning('YouTube API key is not configured.');
            return null;
        }

        try {
            $response = Http::get(config('youtube.base_url') . '/videos', [
                'id'   => $videoId,
                'part' => 'contentDetails',
                'key'  => $key,
            ]);

            if (!$response->successful()) {
                Log::error('YouTube API request failed: ' . $response->body());

                $error  = $response->json('error', []);
                $reason = $error['details'][0]['reason'] ?? ($error['errors'][0]['reason'] ?? null);

                if ($reason === 'API_KEY_INVALID') {
                    return ResponseService::errorResponse(
                        __('youtube_api_key_invalid_please_check_generalsettings')
                    );
                }

                return null;
            }

            $data = $response->json();

            if (empty($data['items'])) {
                Log::warning("No video found for ID: {$videoId}");
                return null;
            }

            $isoDuration = $data['items'][0]['contentDetails']['duration'] ?? null;

            if (!$isoDuration) {
                return null;
            }

            return $this->isoDurationToSeconds($isoDuration);

        } catch (\Exception $e) {
            Log::error('YouTube duration fetch failed: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Extract the 11-character YouTube video ID from a URL,
     * or return the input as-is if it already looks like a bare video ID.
     */
    private function extractVideoId(string $url): ?string
    {
        if (preg_match(
            '%(?:youtube(?:-nocookie)?\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|.*[?&]v=)|youtu\.be/)([^"&?/ ]{11})%i',
            $url,
            $match
        )) {
            return $match[1];
        }

        // Fallback: assume it's already a bare video ID
        if (preg_match('/^[a-zA-Z0-9_-]{11}$/', $url)) {
            return $url;
        }

        return null;
    }

    /**
     * Convert an ISO 8601 duration string (e.g. PT1H2M10S) to seconds.
     */
    private function isoDurationToSeconds(string $isoDuration): int
    {
        $interval = new \DateInterval($isoDuration);

        return ($interval->d * 86400)
            + ($interval->h * 3600)
            + ($interval->i * 60)
            + $interval->s;
    }

    /**
     * Format seconds into HH:MM:SS.
     */
    public function formatDuration(int $seconds): string
    {
        return gmdate('H:i:s', $seconds);
    }
}