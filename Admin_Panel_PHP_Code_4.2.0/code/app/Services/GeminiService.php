<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiService
{
    /**
     * Generate content using Gemini API
     */
    public static function generateContent($prompt)
    {
        // decoding base64 encoded api key
        $api_key = base64_decode(env('GOOGLE_GEMINI_API_KEY'));
        $base_url = config('gemini.base_url');

        try {
             
            $response = Http::timeout(30)->post("{$base_url}?key={$api_key}", [
                'contents' => [
                    ['parts' => [['text' => $prompt]]]
                ]
            ]);

            if ($response->successful()) {
                $data = $response->json();
                return $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
            }

            // Handle API errors
            $err     = $response->json();
            $code  = $err['error']['code'] ?? 400;
            $status  = $err['error']['status'] ?? 'UNKNOWN';
            $message = $err['error']['message'] ?? 'Unknown error';


            $errorMessages = [
                'FAILED_PRECONDITION' => __('gemini_api_free_tier_not_available'),
                'PERMISSION_DENIED'   => __('api_key_does_not_have_required_permissions'),
                'NOT_FOUND'           => __('requested_resource_was_not_found'),
                'RESOURCE_EXHAUSTED'  => __('exceeded_rate_limit'),
                'INTERNAL'            => __('internal_error'),
                'UNAVAILABLE'         => __('temporary_overload_or_down'),
                'DEADLINE_EXCEEDED'   => __('service_unable_to_finish_processing_within_the_deadline'),
            ];

            $userMessage = $errorMessages[$status] ?? __('enter_valid_google_gemini_api_key');

            ResponseService::geminiLogError($response->body(), $message, 'Gemini API Error: ');
            return ResponseService::errorResponse($userMessage, null, $code);

        } catch (\Exception $e) {
            ResponseService::geminiLogError($e->getMessage(), 'Gemini API Exception: ');
            return ResponseService::errorResponse(__('internal_error'), null, 500);
        }
    }

    /**
     * Generate meta keywords
     */
    public static function generateMetaKeywords($title, $content = '', $language_name = '')
    {
        $prompt = "Generate SEO-friendly meta keywords for a news article with the title: '$title' in $language_name language Only return the keywords";
        if ($content) {
            $prompt .= " and content preview: '$content'";
        }
        $prompt .= ". Return only comma-separated keywords, maximum 10 keywords, no explanations.";

        return self::generateContent($prompt);
    }

    /**
     * Generate meta title
     */
    public static function generateMetaTitle($title, $content = '', $language_name = '')
    {
        $prompt = "Create an SEO-optimized meta title for a news article with the title: '$title' in $language_name language Only return the title";
        if ($content) {
            $prompt .= " and content preview: '$content'";
        }
        $prompt .= ". The meta title should be engaging, under 60 characters, and include relevant keywords. Return only the meta title, no explanations.";

        return self::generateContent($prompt);
    }

    /**
     * Generate meta description
     */
    public static function generateMetaDescription($title, $content = '', $language_name = '')
    {
        $prompt = "Write an SEO-friendly meta description for a news article with the title: '$title' in $language_name language Only return the description";
        if ($content) {
            $prompt .= " and content preview: '$content'";
        }
        $prompt .= ". The meta description should be compelling, under 160 characters, and encourage clicks. Return only the meta description, no explanations.";

        return self::generateContent($prompt);
    }

    /**
     * Generate article description/content
     */
    public static function generateDescription($title, $contentType = 'news', $language_name = '')
    {
        $prompt = "Write a comprehensive news article description/content for the title: '$title' in $language_name language Only return the content in html format.";
        // if ($category) {
        //     $prompt .= " in the category: '$category'";
        // }
        $prompt .= ". Create engaging, informative content suitable for a $contentType article. Include relevant details and maintain a professional journalistic tone. Return only the content in html format and Do not wrap the response in ```html or any other markdown syntax., no additional formatting.";

        return self::generateContent($prompt);
    }

    /**
     * generateSummarizedDescription
     * @param string $title
     * @param string $language_name
     * @return string
     */
    public static function generateSummarizedDescription($title, $language_name = ''){
        $prompt = "Generate a summarized description for the title: '$title' in $language_name language Only return the summarized description in 50 words.";
        $prompt .= ". The summarized description should be engaging, under 50 words must be under 300 characters, and include relevant keywords. Return only the summarized description, no explanations.";
        return self::generateContent($prompt);
    }

    /**
     * generateSchemaMarkup
     * @param string $title
     * @param string $language_name
     * @return string
     */
    public static function generateSchemaMarkup($title, $language_name = ''){
        $prompt = "Generate schema markup for the title: '$title' in $language_name language Only return the schema markup in json format.";
        $prompt .= ". The schema markup should be valid json format and should be valid for the title: '$title'.";
        $demoJson = '{
            "@context": "https://schema.org",
            "@type": "NewsArticle",
            "headline": "Popular News",
            "description": "Popular News Here",
            "articleSection": "Breaking News",
            "datePublished": "2023-07-04T18:30:00+00:00",
            "dateModified": "2025-06-25T18:30:00+00:00",
            "author": {
                "@type": "Organization",
                "name": "The Scholarsight"
            },
            "publisher": {
                "@type": "Organization",
                "name": "The Scholarsight",
                "logo": {
                "@type": "ImageObject",
                "url": "https://news-admin.wrteam.me/storage//ad_spaces/1688531909.9771.jpg"
                }
            },
            "image": "https://news-admin.wrteam.me/storage//ad_spaces/1683639229.7089.jpg",
            "mainEntityOfPage": {
                "@type": "WebPage",
                "@id": "https://yourwebsite.com/popular-news"
            }
            }';

            $prompt .= ". The schema markup should be valid json format and should be valid for the title: '$title'. The schema markup should be like this: $demoJson";

        return self::generateContent($prompt);
    }

    /**
     * generateMetaFieldsWithOnePrompt
     * @param string $title
     * @param string $language_name
     * @param bool $includeDescription
     * @param bool $includeSummarizedDescription
     * @return array
     */
    public static function generateMetaFieldsWithOnePrompt($title, $language_name){
        // $prompt = "Generate SEO-friendly meta keywords for a news article with the title: '$title' in $language_name language. Only return a comma-separated list of up to 10 keywords.

        // Create an SEO-optimized meta title for a news article with the title: '$title' in $language_name language. The meta title should be engaging, under 60 characters, and include relevant keywords. Only return the title.

        // Write an SEO-friendly meta description for a news article with the title: '$title' in $language_name language. The meta description should be compelling, under 160 characters, and encourage clicks. Only return the description.";

        $prompt = "Generate SEO-friendly meta keywords, an SEO-optimized meta title, and an SEO-friendly meta description for a news article with the title: '$title' in $language_name language.

            The meta keywords should be a comma-separated list of up to 10 keywords.
            The meta title should be engaging, under 60 characters, and include relevant keywords.
            The meta description should be compelling, under 160 characters, and encourage clicks.

            Return the output in a JSON object with the keys 'meta_keywords', 'meta_title', and 'meta_description' so that it can be accessed programmatically. Each of 'meta_keywords', 'meta_title' and 'meta_description' must be 300 characters or fewer.";

        return self::generateContent($prompt);
    }

    public static function generateAllMetaFields($title, $language_name, $includeDescription = false, $includeSummarizedDescription = false)
    {

        $metaFields = self::generateMetaFieldsWithOnePrompt($title, $language_name);
        $metaFields = str_replace('```json', '', $metaFields);
        $metaFields = str_replace('```', '', $metaFields);

        $metaFields = json_decode($metaFields, true);

        $result = [
            'meta_keywords' => $metaFields['meta_keywords'],
            'meta_title' => $metaFields['meta_title'],
            'meta_description' => $metaFields['meta_description']
        ];

        // if ($includeSchemaMarkup) {
        //     $schema_markup = self::generateSchemaMarkup($title, $language_name);
        //     $result['schema_markup'] = $schema_markup;
        // }


        // Optionally include description if requested
        if ($includeDescription == 'true') {

            $description = self::generateDescription($title, $language_name);
            $description = str_replace('```html', '', $description);
            $description = str_replace('```', '', $description);
            $result['description'] = $description;
        }
         
        return $result;
    }
}
