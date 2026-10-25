<?php

namespace App\Models;

use App\Traits\HasSafeOrder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class BreakingNews extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'tbl_breaking_news';

    protected $fillable = ['title', 'image', 'content_type', 'content_value', 'description', 'summarized_description', 'language_id', 'slug', 'meta_title', 'meta_description', 'meta_keyword', 'schema_markup'];

    public function getImageAttribute($image)
    {
        if (!empty($image) && strpos($image, 'breaking_news/') === false) {
            $image = 'breaking_news/' . $image;
        }
        return $image && Storage::disk('public')->exists($image) ? url(Storage::url($image)) : '';
    }

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function breaking_news_view()
    {
        return $this->hasMany(BreakingNewsView::class, 'breaking_news_id');
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($breaking_news) {
            // before delete() method call this
            if (!is_null($breaking_news->image) && Storage::disk('public')->exists($breaking_news->getRawOriginal('image'))) {
                Storage::disk('public')->delete($breaking_news->getRawOriginal('image'));
            }
            if (!is_null($breaking_news->content_value) && Storage::disk('public')->exists($breaking_news->getRawOriginal('content_value'))) {
                Storage::disk('public')->delete($breaking_news->getRawOriginal('content_value'));
            }
            $breaking_news->breaking_news_view()->delete();
        });
    }
}
