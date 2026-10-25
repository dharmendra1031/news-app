<?php

namespace App\Services;

class ReadTimeService
{
    /**
     * Word-count based read time (minutes) at 200 wpm, minimum 1.
     * Description is treated as HTML: tags stripped and entities decoded
     * before counting words.
     */
    public static function estimate(?string $description): int
    {
        $text = html_entity_decode(strip_tags((string) $description), ENT_QUOTES | ENT_HTML5, 'UTF-8');
        $text = preg_replace('/\s+/u', ' ', trim($text));
        $wordCount = $text === '' ? 0 : count(preg_split('/\s+/u', $text));
        return max(1, (int) ceil($wordCount / 200));
    }
}
