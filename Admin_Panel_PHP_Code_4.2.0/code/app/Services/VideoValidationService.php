<?php

namespace App\Services;

class VideoValidationService
{
    private const MAX_RESOLUTION = 1920;
    private const MAX_DURATION   = 120;
    private const MIN_DURATION   = 3;

    public static function validateMetadata($file, $validator): void
    {
        if (!class_exists('\getID3') || !$file || !$file->isValid()) {
            return;
        }

        $getID3 = new \getID3();
        $info   = $getID3->analyze($file->getRealPath());

        if (!isset($info['video'])) {
            return;
        }

        $width    = $info['video']['resolution_x'] ?? 0;
        $height   = $info['video']['resolution_y'] ?? 0;
        $duration = (float) ($info['playtime_seconds'] ?? 0);

        if (max($width, $height) > self::MAX_RESOLUTION) {
            $validator->errors()->add('video_file', __('video_resolution_too_high', [
                'width'         => $width,
                'height'        => $height,
                'maxResolution' => self::MAX_RESOLUTION,
            ]));
        }

        if ($duration > self::MAX_DURATION) {
            $validator->errors()->add('video_file', __('video_duration_too_long', [
                'duration'    => (int) $duration,
                'maxDuration' => self::MAX_DURATION,
            ]));
        }

        if ($duration > 0 && $duration < self::MIN_DURATION) {
            $validator->errors()->add('video_file', __('video_duration_too_short', [
                'duration'    => (int) $duration,
                'minDuration' => self::MIN_DURATION,
            ]));
        }
    }
}
