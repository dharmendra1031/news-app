<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class AdSpaces extends Model
{
    use HasFactory;

    protected $table = 'tbl_ad_spaces';

    protected $fillable = [
        // 'ad_space',
        'ad_featured_section_id',
        'ad_image',
        'web_ad_image',
        'ad_url',
        'page',
        'platform',
        'placement',
        'ad_type',
        'duration_days',
        'start_date',
        'end_date',
        'language_id',
        // 'date',
        'status'
    ];

    protected $hidden = [
        'created_at',
        'updated_at'
    ];


    public static function getPlatforms(): array
    {
        return array_keys(config('ad_spaces.platforms', []));
    }

    public static function getPagesForPlatform(string $platform): array
    {
        return array_keys(config("ad_spaces.platforms.{$platform}", []));
    }

    public static function getPages(): array
    {
        $pages = [];
        foreach ((array) config('ad_spaces.platforms', []) as $platformPages) {
            foreach (array_keys((array) $platformPages) as $page) {
                $pages[$page] = true;
            }
        }
        return array_keys($pages);
    }

    public static function getPlacements(string $page, string $platform): array
    {
        return array_keys((array) config("ad_spaces.platforms.{$platform}.{$page}", []));
    }

    public function getAdImageAttribute($AdImage)
    {
        if (!empty($AdImage) && strpos($AdImage, 'ad_spaces/') === false) {
            $AdImage = 'ad_spaces/' . $AdImage;
        }
        return $AdImage && Storage::disk('public')->exists($AdImage) ? url(Storage::url('' . $AdImage)) : '';
    }

    public function getWebAdImageAttribute($WebAdImage)
    {
        if (!empty($WebAdImage) && strpos($WebAdImage, 'ad_spaces/') === false) {
            $WebAdImage = 'ad_spaces/' . $WebAdImage;
        }
        return $WebAdImage && Storage::disk('public')->exists($WebAdImage) ? url(Storage::url('' . $WebAdImage)) : '';
    }

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function feature_section()
    {
        return $this->belongsTo(FeaturedSections::class, 'ad_featured_section_id');
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($image) {
            // before delete() method call this
            if (!is_null($image->ad_image) && Storage::disk('public')->exists($image->getRawOriginal('ad_image'))) {
                Storage::disk('public')->delete($image->getRawOriginal('ad_image'));
            }
            if (!is_null($image->web_ad_image) && Storage::disk('public')->exists($image->getRawOriginal('web_ad_image'))) {
                Storage::disk('public')->delete($image->getRawOriginal('web_ad_image'));
            }
        });
    }

    public function getExpiryDaysAttribute()
    {
        $endDate = Carbon::parse($this->attributes['end_date']);
        if ($endDate->lte(Carbon::now())) {
            return '-';
        }
        return $endDate->diffInDays(Carbon::now());
    }
    /**
     * Scope to filter active and currently valid ad banners
     *
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeActiveBanners($query)
    {
        $today = Carbon::now()->toDateString();

        $query->where('status', 1)
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today);

        return $query;
    }
}
