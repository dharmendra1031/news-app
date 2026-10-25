<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasSafeOrder;

class Alerts extends Model
{
    use HasFactory, HasSafeOrder;
    protected $table = "alerts";
    protected $orderable = ['id', 'alert_type', 'name', 'symbol', 'current_price', 'percent_change', 'last_updated_at'];
    protected $fillable = ['alert_type',
                           'name',
                           'symbol',
                           'exchange',
                           'ipo_price',
                           'current_price',
                           'currency',
                           'percent_change',
                           'direction',
                           'status',
                           'last_updated_at'];

}