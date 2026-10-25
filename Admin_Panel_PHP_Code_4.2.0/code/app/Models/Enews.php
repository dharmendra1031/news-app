<?php

namespace App\Models;

use App\Traits\HasSafeOrder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Enews extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'tbl_e_news';

    protected $fillable = [
        'language_id',
        'title',
        'slug',
        'description',
        'thumbnail',
        'attachment',
        'date',
        'meta_keyword',
        'meta_title',
        'meta_description',
        'schema_markup',
        'status',
    ];

    protected $orderable = ['id', 'title', 'slug', 'date', 'status'];

    protected $hidden = [
        'created_at',
        'updated_at',
    ];
    // thumbnail
    public function getThumbnailAttribute($thumbnail)
    {
        if (!$thumbnail || !Storage::disk('public')->exists($thumbnail)) {
            return null;
        }
        return url(Storage::url($thumbnail));
        // return Storage::url($thumbnail); // used when FILESYSTEM_DISK is set to public
    }

    // attachment
    public function getAttachmentAttribute($attachment)
    {
        if (!$attachment || !Storage::disk('public')->exists($attachment)) {
            return null;
        }
        return url(Storage::url($attachment));
    }

    // date format DD-MM-YYYY
    // public function getDateAttribute($date)
    // {
    //     return $date ? date('d-m-Y', strtotime($date)) : null;
    // }

    // scopes
    public function scopeSearch($query, $search, $languageId)
    {
        return $query->when($languageId, function ($q) use ($languageId) {
            $q->where('language_id', $languageId);
        })->when($search, function ($q) use ($search) {
            $q->where(function ($q2) use ($search) {
                $q2->where('title', 'like', "%{$search}%")
                   ->orWhere('slug', 'like', "%{$search}%")
                   ->orWhere('description', 'like', "%{$search}%");
                //    ->orWhere('meta_keyword', 'like', "%{$search}%")
                //    ->orWhere('meta_title', 'like', "%{$search}%")
                //    ->orWhere('meta_description', 'like', "%{$search}%");
            });
        });
    }


    // relationships
    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }
}
