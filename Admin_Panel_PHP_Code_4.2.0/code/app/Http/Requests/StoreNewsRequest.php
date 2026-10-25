<?php

namespace App\Http\Requests;

use App\Services\ResponseService;
use Illuminate\Foundation\Http\FormRequest;

class StoreNewsRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        ResponseService::noPermissionThenRedirect('news-create');
        $isDraft = $this->input('is_draft', 0);

        // If is_draft is 1, only require minimal fields
        if ($isDraft == 1 || $isDraft === '1' || $isDraft === true) {
            $rules = [
                'language' => 'required',
                'title' => 'required|string|max:255',
                'slug' => 'required|string|max:255',
                'is_draft' => 'nullable|boolean',
            ];

            // Add category_id if category is enabled
            if (is_category_enabled() == 1) {
                $rules['category_id'] = 'required';
            }

            return $rules;
        }

        // Full validation rules for non-draft news
        $rules = [
            'language' => 'required',
            'title' => 'required|string|max:255',
            'slug' => 'required|string|max:255',
            'published_date' => 'nullable',
            'content_type' => 'required|string',
            'file' => 'required|image:png,jpg,jpeg,svg,webp',
            'summarized_description' => 'nullable|string|max:300',
            'des' => 'nullable|string',
            'is_draft' => 'nullable|boolean',
        ];

        // Conditional video file validation
        if ($this->input('content_type') == 'video_upload') {
            $rules['video_file'] = 'nullable|mimes:mp4,mov,avi|max:20480';
        }

        // Conditional youtube URL validation
        if ($this->input('content_type') == 'video_youtube') {
            $rules['youtube_url'] = 'required|youtube_url';
        }

        // Conditional other URL validation
        if ($this->input('content_type') == 'video_other') {
            $rules['other_url'] = 'nullable|url';
        }

        // Add category_id if category is enabled
        if (is_category_enabled() == 1) {
            $rules['category_id'] = 'required';
        }

        // Add location_id if location news is enabled
        if (is_location_news_enabled() == 1) {
            $rules['location_id'] = 'required';
        }

        return $rules;
    }

    /**
     * Get custom validation error messages.
     */
    // public function messages(): array
    // {
    //     return [
    //         'des.required' => __('description_field_required'),
    //     ];
    // }
}

