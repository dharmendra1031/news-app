<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Traits\HasSafeOrder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class LiveStreaming extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'tbl_live_streaming';

    protected $fillable = ['title', 'image', 'type', 'url', 'language_id', 'meta_description', 'meta_title', 'meta_keyword', 'schema_markup'];

    protected $orderable = ['id', 'title', 'created_at'];

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function getImageAttribute($image)
    {
        // Log::info("image: " . $image);
        // If type is File Upload or Video Upload and liveStreaming is not in the image path, add it.
        if (!empty($image) && strpos($image, 'liveStreaming/') === false) {
            $image = 'liveStreaming/' . $image;
        }

        return $image && Storage::disk('public')->exists($image) ? url(Storage::url($image)) : '';
        // return url(Storage::url($image));
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($image) {
            // before delete() method call this
            if (!is_null($image->image) && Storage::disk('public')->exists($image->getRawOriginal('image'))) {
                Storage::disk('public')->delete($image->getRawOriginal('image'));
            }
        });
    }

    // scopes
    public function scopeWithCommonFields($query)
    {
        return $query->select(
            'tbl_live_streaming.id',
            'tbl_live_streaming.title',
            'tbl_live_streaming.image',
            'tbl_live_streaming.type as content_type',
            'tbl_live_streaming.url as content_value',
            'tbl_live_streaming.created_at as date',
            'tbl_live_streaming.created_at as published_date',
            DB::raw('"live_streaming" as source_type'),
            DB::raw('NULL as description'),
            DB::raw('NULL as category_id'),
            DB::raw('NULL as subcategory_id'),
            DB::raw('NULL as tag_id'),
            DB::raw('NULL as category_name'),
            DB::raw('NULL as category_slug'),
            DB::raw('NULL as slug')
        );
    }

    // scope for search by title
    public function scopeSearch($query, $search)
    {
        return $query->when($search, function ($q) use ($search) {
            $q->where('title', 'like', '%' . $search . '%');
        });
    }

}
