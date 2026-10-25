<?php

namespace App\Http\Controllers;

/**
 * @deprecated All methods have been migrated to focused controllers under
 *             App\Http\Controllers\Api\. This class is kept as an empty
 *             placeholder to avoid hard-breaking any web routes or console
 *             commands that still reference it by name.
 *
 * Migration map:
 *  - News, slug, author news  → Api\NewsApiController
 *  - Comments, flags, likes   → Api\CommentApiController
 *  - Bookmarks, news likes    → Api\BookmarkLikeApiController
 *  - Users, tokens, author    → Api\UserApiController
 *  - Videos, live streaming   → Api\MediaApiController
 *  - Breaking news, featured, e-news, feeds → Api\ContentApiController
 *  - Settings, categories, pages, etc.      → Api\SettingsApiController
 *  - RSS, survey/questions    → Api\RssApiController
 *  - survey/questions    → Api\SurveyApiController
 */
class ApiController extends Controller
{
    // Intentionally empty — all endpoints now live in App\Http\Controllers\Api\
}
