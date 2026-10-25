<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use App\Traits\HasSafeOrder;

class WebSeoPages extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'tbl_web_seo_pages';

    protected $fillable = ['language_id', 'page_type', 'meta_title', 'meta_keyword', 'meta_description', 'schema_markup', 'og_image'];

    protected $orderable = ['id', 'page_type', 'meta_title', 'meta_keyword', 'meta_description', 'schema_markup', 'og_image'];

    public function getOgImageAttribute($image)
    {
        if (!empty($image) && strpos($image, 'web_seo_pages/') === false) {
            $image = 'web_seo_pages/' . $image;
        }

        return $image && Storage::disk('public')->exists($image) ? url(Storage::url('/' . $image)) : '';
    }

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($image) {
            // before delete() method call this
            if (!is_null($image->og_image) && Storage::disk('public')->exists($image->getRawOriginal('og_image'))) {
                Storage::disk('public')->delete($image->getRawOriginal('og_image'));
            }
        });
    }
}
