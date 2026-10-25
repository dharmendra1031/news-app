<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WebSetting extends Model
{
    use HasFactory;

    protected $table = 'tbl_web_settings';

    protected $fillable = ['type', 'message'];

    public function scopeOfType($query, string $type)
    {
        return $query->where('type', $type);
    }

    public function scopeOfTypes($query, array $types)
    {
        return $query->whereIn('type', $types);
    }
}
