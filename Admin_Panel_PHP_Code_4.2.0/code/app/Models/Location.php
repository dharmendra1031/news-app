<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Traits\HasSafeOrder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Location extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'tbl_location';

    protected $fillable = ['location_name', 'latitude', 'longitude'];

    protected $orderable = ['id', 'location_name', 'latitude', 'longitude'];

    public function news()
    {
        return $this->hasMany(News::class, 'location_id');
    }

    public function notification()
    {
        return $this->hasMany(SendNotification::class, 'location_id');
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($location) {
            $location->news()->each(function ($news) {
                if (!is_null($news->image) && Storage::disk('public')->exists($news->getRawOriginal('image'))) {
                    Storage::disk('public')->delete($news->getRawOriginal('image'));
                }
                $newsDirectory = 'news/' . $news->id;
                if (Storage::disk('public')->exists($newsDirectory)) {
                    Storage::disk('public')->deleteDirectory($newsDirectory);
                }
                $news->images()->each(function ($subnews) {
                    $filePath2 = $subnews->getRawOriginal('other_image');
                    if (!is_null($subnews->other_image) && Storage::disk('public')->exists($filePath2)) {
                        Storage::disk('public')->delete($filePath2);
                    }
                });
                $news->images()->delete();
            });
            $location->news()->delete();
            $location->notification()->each(function ($notification) {
                if (!is_null($notification->image) && Storage::disk('public')->exists($notification->getRawOriginal('image'))) {
                    Storage::disk('public')->delete($notification->getRawOriginal('image'));
                }
            });
            $location->notification()->delete();
        });
    }
}
