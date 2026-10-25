<?php

namespace App\Services;

use App\Models\Language;
use App\Models\Podcasts;
use App\Models\PodcastEpisodes;
use App\Models\PodcastFollow;
use App\Models\Settings;
use App\Models\Token;

class PodcastNotificationService
{
    /**
     * Push an FCM notification to every user following the given podcast.
     */
    public function notifyFollowers(Podcasts $podcast, PodcastEpisodes $episode): void
    {
        $followerUserIds = PodcastFollow::where('podcast_id', $podcast->id)
            ->pluck('user_id')
            ->toArray();

        if (empty($followerUserIds)) {
            return;
        }

        $fcmMsg = [
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            'title'        => __('new_episode') . ' : '.$episode->title,
            'body'         => $episode->description,
            'type'         => 'all',
            'podcast_slug' => $podcast->slug,
        ];

        $languageIds = Language::where('status', 1)->pluck('id');

        foreach ($languageIds as $languageId) {
            $deviceTokens = Token::whereIn('user_id', $followerUserIds)
                ->where('language_id', $languageId)
                ->pluck('token')
                ->toArray();

            if (!empty($deviceTokens)) {
                send_notification($fcmMsg, $languageId, 0, $deviceTokens, config('notification_types.PODCASTS'));
            }
        }

        // Tokens with no language set (language_id null) are skipped by the loop above -
        // send those under the default language so those followers aren't dropped.
        $unlocalizedTokens = Token::whereIn('user_id', $followerUserIds)
            ->whereNull('language_id')
            ->pluck('token')
            ->toArray();

        if (!empty($unlocalizedTokens)) {
            $defaultLanguageId = Settings::where('type', 'default_language')->value('message') ?? 1;
            send_notification($fcmMsg, $defaultLanguageId, 0, $unlocalizedTokens, config('notification_types.PODCASTS'));
        }
    }
}
