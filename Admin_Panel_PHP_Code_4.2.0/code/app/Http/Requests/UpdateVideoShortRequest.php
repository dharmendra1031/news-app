<?php

namespace App\Http\Requests;

use App\Services\VideoValidationService;
use Illuminate\Foundation\Http\FormRequest;

class UpdateVideoShortRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $rules = [
            'edit_id'        => 'required|integer|exists:video_shorts,id',
            'language'       => 'required|integer|exists:tbl_languages,id',
            'title'          => 'required|string|max:255',
            'slug'           => 'required|string|max:255',
            'video_file'     => 'nullable|file|mimes:mp4,webm,avi,mov|max:25600',
            'des'            => 'nullable|string|max:255',
            'published_date' => 'nullable|date',
            'status'         => 'nullable|in:0,1',
        ];

        if (is_category_enabled() == 1) {
            $rules['category_id'] = 'required|integer|exists:tbl_category,id';
        }

        return $rules;
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $file = $this->file('video_file');
            if (!$file || !$file->isValid()) {
                return;
            }
            VideoValidationService::validateMetadata($file, $validator);
        });
    }
}
