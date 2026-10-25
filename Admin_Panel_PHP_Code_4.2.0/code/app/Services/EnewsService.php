<?php

namespace App\Services;

use App\Models\Enews;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Throwable;

class EnewsService
{
   /**
     * Get validation rules for ad banner
     *
     * @param bool $isUpdate
     * @return array
     */
    public static function getValidationRules(bool $isUpdate = false): array
    {
        $filePresence = $isUpdate ? 'nullable' : 'required';

        return [
            'language' => 'required',
            'title' => 'required|string|max:255',
            'slug' => 'required|string|max:255',
            'description' => 'nullable|string',
            'thumbnail' => $filePresence . '|image|mimes:jpeg,png,jpg,gif,svg,webp|max:2048',
            'attachment' => $filePresence . '|file|mimes:pdf|max:51200',
            'date' => ($isUpdate ? 'nullable' : 'required') . '|date',
            'meta_keyword' => 'nullable|string',
            'meta_title' => 'nullable|string',
            'meta_description' => 'nullable|string',
            'schema_markup' => 'nullable|string',
        ];
    }

     /**
     * Prepare data array for creating/updating Enews
     *
     * @param Request $request
     * @param string|null $existingImage
     * @return array
     */
    public static function prepareEnewsData(Request $request, string $slug, bool $isUpdate = false): array
    {
        $meta_keyword = json_decode($request->meta_keyword, true);

        $data = [
            'language_id' => $request->language,
            'title' => $request->title,
            'slug' => $slug,
            'description' => $request->description ?? null,
            'date' => $request->date,
            'meta_keyword' => $meta_keyword ? get_meta_keyword($meta_keyword) : null,
            'meta_title' => $request->meta_title ?? null,
            'meta_description' => $request->meta_description ?? null,
            'schema_markup' => $request->schema_markup ?? null,
            'status' => $request->status,
        ];

        if ($request->hasFile('thumbnail')) {
            $data['thumbnail'] = compressAndUpload($request->thumbnail, 'enews');
        } elseif (!$isUpdate) {
            $data['thumbnail'] = null;
        }

        if ($request->hasFile('attachment')) {
            $data['attachment'] = compressAndUpload($request->attachment, 'enews');
        } elseif (!$isUpdate) {
            $data['attachment'] = null;
        }

        return $data;
    }


     /**
     * Create a new ad banner
     *
     * @param Request $request
     * @return Enews
     * @throws Throwable
     */
    public static function createEnews(Request $request, string $slug): Enews
    {
        DB::beginTransaction();
        try {
            $data = self::prepareEnewsData($request, $slug, false);

            $enews = Enews::create($data);

            DB::commit();
            return $enews;
        } catch (Throwable $th) {
            DB::rollBack();
            throw $th;
        }
    }

       /**
     * Update an existing ad banner
     *
     * @param Request $request
     * @param string $id
     * @return Enews
     * @throws Throwable
     */
    public static function updateEnews(Request $request, string $slug, string $id): Enews
    {
        DB::beginTransaction();
        try {
            $enews = Enews::findOrFail($id);

            $data = self::prepareEnewsData($request, $slug, true);

            $enews->update($data);

            DB::commit();
            return $enews;
        } catch (Throwable $th) {
            DB::rollBack();
            throw $th;
        }
    }


      /**
     * Delete an ad banner
     *
     * @param string $id
     * @return bool
     * @throws Throwable
     */
    public static function deleteEnews(string $id): bool
    {
        try {
            $enews = Enews::findOrFail($id);

            $thumbnail = $enews->getRawOriginal('thumbnail') ?? null;
            if ($thumbnail && Storage::disk('public')->exists($thumbnail)) {
                Storage::disk('public')->delete($thumbnail);
            }

            $attachment = $enews->getRawOriginal('attachment') ?? null;
            if ($attachment && Storage::disk('public')->exists($attachment)) {
                Storage::disk('public')->delete($attachment);
            }

            return $enews->delete();
        } catch (Throwable $th) {
            throw $th;
        }
    }
}
