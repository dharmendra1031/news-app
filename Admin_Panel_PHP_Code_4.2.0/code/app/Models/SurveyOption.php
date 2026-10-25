<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SurveyOption extends Model
{
    use HasFactory;

    protected $table = 'tbl_survey_option';

    protected $fillable = ['question_id', 'options', 'counter'];

    public function result()
    {
        return $this->hasMany(SurveyResult::class, 'option_id');
    }
}
