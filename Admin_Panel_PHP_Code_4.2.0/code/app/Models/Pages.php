<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Traits\HasSafeOrder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Pages extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'tbl_pages';

    protected $fillable = ['title', 'slug', 'meta_description', 'meta_keywords', 'is_custom', 'page_content', 'page_type', 'language_id', 'page_icon', 'is_termspolicy', 'is_privacypolicy', 'status', 'schema_markup', 'meta_title', 'og_image'];

    protected $orderable = ['id', 'title', 'slug', 'language_id', 'status'];

    protected $hidden = ['created_at', 'updated_at'];

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function getPageIconAttribute($page_icon)
    {
        if (!empty($page_icon) && strpos($page_icon, 'pages/') === false) {
            $page_icon = 'pages/' . $page_icon;
        }
        return $page_icon && Storage::disk('public')->exists($page_icon) ? url(Storage::url('/' . $page_icon)) : '';
    }

    public function getOgImageAttribute($og_image)
    {
        return $og_image && Storage::disk('public')->exists($og_image) ? url(Storage::url('/' . $og_image)) : '';
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($image) {
            // before delete() method call this
            if (!is_null($image->page_icon) && Storage::disk('public')->exists($image->getRawOriginal('page_icon'))) {
                Storage::disk('public')->delete($image->getRawOriginal('page_icon'));
            }
            if (!is_null($image->og_image) && Storage::disk('public')->exists($image->getRawOriginal('og_image'))) {
                Storage::disk('public')->delete($image->getRawOriginal('og_image'));
            }
        });
    }
}
