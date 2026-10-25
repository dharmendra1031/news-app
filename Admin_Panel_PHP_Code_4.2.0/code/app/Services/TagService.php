<?php

namespace App\Services;

use App\Models\Tag;

class TagService
{
    /**
     * Resolve an array of integer tag IDs from a raw request value.
     *
     * Accepts a JSON-encoded string or a plain array of tag items.
     * Each item may have an existing `id` (reused) or a `value` (new tag created).
     *
     * @param  mixed           $rawTagId   $request->tag_id (string|array|null)
     * @param  int|string      $languageId Language ID for newly created tags
     * @return int[]
     */
    public static function resolveTagIds(mixed $rawTagId, int|string $languageId): array
    {
        $tagItems = is_string($rawTagId)
            ? (json_decode($rawTagId, true) ?? [])
            : (is_array($rawTagId) ? $rawTagId : []);

        return collect($tagItems)->map(function ($item) use ($languageId) {
            if (!empty($item['id'])) {
                return (int) $item['id'];
            }
            if (!empty($item['value'])) {
                return (new self())->createNewTag($item['value'], $languageId, null);
            }
            return null;
        })->filter()->values()->toArray();
    }

    public function createNewTag($name, $languageId, $id = null)
    {
        if ($id != null) {
            return $id;
        }

        $slug = generateUniqueSlug($name);
        $tag = Tag::where(['language_id' => $languageId, 'slug' => $slug])->first();
        if ($tag) {
            return $tag->id;
        }

        $tag = Tag::create([
            'language_id'      => $languageId,
            'slug'             => $slug,
            'tag_name'         => $name,
            'meta_title'       => null,
            'meta_description' => null,
            'meta_keyword'     => null,
            'schema_markup'    => null,
            'og_image'         => null,
        ]);

        return $tag->id;
    }
}

