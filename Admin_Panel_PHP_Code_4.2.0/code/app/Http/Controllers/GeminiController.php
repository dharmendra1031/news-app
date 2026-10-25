<?php

namespace App\Http\Controllers;

use App\Services\GeminiService;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class GeminiController extends Controller
{
    //
    public function generateAIContent(Request $request)
    {
        try {
            // $geminiService = new GeminiService();

            $fieldType = $request->input('field_type');
            $title = $request->input('title', '');
            // $content = $request->input('content', '');
            // $category = $request->input('category', '');

            $generatedContent = '';

            switch ($fieldType) {
                case 'meta_keywords':
                    $generatedContent = GeminiService::generateMetaKeywords($title);
                    break;

                case 'meta_title':
                    $generatedContent = GeminiService::generateMetaTitle($title);
                    break;

                case 'meta_description':
                    $generatedContent = GeminiService::generateMetaDescription($title);
                    break;

                case 'description':
                    $generatedContent = GeminiService::generateDescription($title);
                    break;

                default:
                    return response()->json([
                        'success' => false,
                        'message' => 'Invalid field type'
                    ], 400);
            }

            if ($generatedContent) {
                return response()->json([
                    'success' => true,
                    'content' => trim($generatedContent),
                    'message' => 'Content generated successfully!'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to generate content. Please try again.'
                ], 500);
            }

        } catch (Exception $e) {
            Log::error('AI Content Generation Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'An error occurred while generating content.'
            ], 500);
        }
    }
    /**
     * Generate all meta fields at once
     */
    public function generateAllMetaFields(Request $request)
    {
        try {

            // checking google gemini api key is set or not
            $api_key = env('GOOGLE_GEMINI_API_KEY');
            if (!$api_key) {
                ResponseService::errorResponse(__('google_gemini_api_key_not_set'), null, 500, null);
            }
            $title = $request->input('title', '');
            // $content = $request->input('content', '');
            // $category = $request->input('category', '');
            $language_name = $request->input('language_name', '');
            $includeDescription = $request->input('includeDescription', false); // Optional parameter
            $includeSummarizedDescription = $request->input('includeSummarizedDescription', false); // Optional parameter
            // $includeSchemaMarkup = $request->input('include_schema_markup', false); // Optional parameter

            if (!$title) {
                return response()->json([
                    'success' => false,
                    'message' => 'Title is required to generate meta fields'
                ], 400);
            }

            // Call the service with the optional description parameter
            $metaFields = GeminiService::generateAllMetaFields($title, $language_name, $includeDescription, $includeSummarizedDescription);

            if($includeSummarizedDescription == 'true'){
                $summarizedDescription = GeminiService::generateSummarizedDescription($title, $language_name);
            }


            // Prepare the response data (meta fields hard-capped at 300 chars each)
            $responseData = [
                'meta_keywords' => mb_substr(trim($metaFields['meta_keywords']), 0, 300),
                'meta_title' => mb_substr(trim($metaFields['meta_title']), 0, 300),
                'meta_description' => mb_substr(trim($metaFields['meta_description']), 0, 300),
            ];

            // if($includeSchemaMarkup && isset($metaFields['schema_markup'])){
            //     $responseData['schema_markup'] = trim($metaFields['schema_markup']);
            // }


            // Add description if it was generated
            if ($includeDescription && isset($metaFields['description'])) {
                $responseData['description'] = trim($metaFields['description']);
            }

            // Add summarized description if it was generated (also capped at 300 chars)
            if($includeSummarizedDescription && isset($summarizedDescription) && $summarizedDescription != ''){
                $responseData['summarized_description'] = mb_substr(trim($summarizedDescription), 0, 300);
            }

            // Check if required meta fields are present
            if ($metaFields &&
                isset($metaFields['meta_keywords']) &&
                isset($metaFields['meta_title']) &&
                isset($metaFields['meta_description'])) {

                $message = $includeDescription ?
                    'All meta fields and description generated successfully!' :
                    'All meta fields generated successfully!';

                $message .= $includeSummarizedDescription ?
                    ' and summarized description generated successfully!' :
                    '';

                return response()->json([
                    'success' => true,
                    'data' => $responseData,
                    'message' => $message
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => __('failed_to_generate_meta_fields')
                ], 500);
            }

        } catch (Exception $e) {
            // Log::error('All Meta Fields Generation Error: ' . $e->getMessage());
            ResponseService::logErrorResponse($e, 'Gemini controller (generateAllMetaFields()): ' . $e->getMessage());


            return response()->json([
                'success' => false,
                'message' => __('enter_valid_google_gemini_api_key')
            ], 500);
        }
    }

    /**
     * Bulk generate content for multiple fields
     */
    public function bulkGenerate(Request $request)
    {
        try {
            $geminiService = new GeminiService();

            $title = $request->input('title', '');
            $content = $request->input('content', '');
            $category = $request->input('category', '');
            $fields = $request->input('fields', []); // Array of field types to generate

            if (!$title) {
                return response()->json([
                    'success' => false,
                    'message' => 'Title is required to generate content'
                ], 400);
            }

            if (empty($fields)) {
                return response()->json([
                    'success' => false,
                    'message' => 'At least one field type must be specified'
                ], 400);
            }

            $results = [];
            $errors = [];

            foreach ($fields as $fieldType) {
                try {
                    switch ($fieldType) {
                        case 'meta_keywords':
                            $results[$fieldType] = $geminiService->generateMetaKeywords($title, $content);
                            break;
                        case 'meta_title':
                            $results[$fieldType] = $geminiService->generateMetaTitle($title, $content);
                            break;
                        case 'meta_description':
                            $results[$fieldType] = $geminiService->generateMetaDescription($title, $content);
                            break;
                        case 'description':
                            $results[$fieldType] = $geminiService->generateDescription($title, $category);
                            break;
                        default:
                            $errors[] = "Invalid field type: $fieldType";
                    }
                } catch (Exception $e) {
                    $errors[] = "Failed to generate $fieldType: " . $e->getMessage();
                }
            }

            if (!empty($results)) {
                return response()->json([
                    'success' => true,
                    'data' => $results,
                    'errors' => $errors,
                    'message' => 'Content generated for ' . count($results) . ' field(s)'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to generate any content',
                    'errors' => $errors
                ], 500);
            }

        } catch (Exception $e) {
            Log::error('Bulk Generation Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'An error occurred during bulk generation.'
            ], 500);
        }
    }

    /**
     * Get generation statistics and usage
     */
    public function getGenerationStats(Request $request)
    {
        try {
            // You can implement usage tracking here
            // For now, return basic stats

            return response()->json([
                'success' => true,
                'data' => [
                    'total_generations' => 0, // Implement tracking
                    'fields_available' => [
                        'meta_keywords' => 'SEO Keywords',
                        'meta_title' => 'Meta Title',
                        'meta_description' => 'Meta Description',
                        'description' => 'Article Content'
                    ],
                    'max_chars' => [
                        'meta_title' => 60,
                        'meta_description' => 160,
                        'meta_keywords' => 255
                    ]
                ]
            ]);

        } catch (Exception $e) {
            Log::error('Generation Stats Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch generation statistics'
            ], 500);
        }
    }
}
