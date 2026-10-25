<?php

namespace App\Http\Requests;

use App\Services\VideoValidationService;
use Illuminate\Foundation\Http\FormRequest;

class StoreVideoShortRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $rules = [
            'language'       => 'required|integer|exists:tbl_languages,id',
            'title'          => 'required|string|max:255',
            'slug'           => 'required|string|max:255|unique:video_shorts,slug',
            'video_type'     => 'required|string',
            'youtube_url'    => 'nullable|string',
            'video_file'     => ['nullable','file','max:25600', function ($attribute, $value, $fail) {
                                        $allowedExtensions = ['mp4', 'webm', 'mov'];
                                        $allowedMimes = [
                                            'video/mp4',
                                            'video/webm',
                                            'video/x-matroska', // webm sometimes sniffs as this
                                            'video/x-msvideo',
                                            'video/quicktime',
                                        ];

                                        $ext = strtolower($value->getClientOriginalExtension());
                                        $mime = $value->getMimeType();

                                        if (!in_array($ext, $allowedExtensions, true) || !in_array($mime, $allowedMimes, true)) {
                                            $fail(trans('The video file field must be a file of type: mp4, webm, mov.'));
                                        }
                                    },
                                ],
            'des'            => 'nullable|string|max:255',
            'published_date' => 'nullable|date',
            'status'         => 'nullable|boolean',
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
