<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SurveyResult extends Model
{
    use HasFactory;

    protected $table = 'tbl_survey_result';

    protected $fillable = ['question_id', 'option_id', 'user_id', 'result'];

    public function question()
    {
        return $this->belongsTo(SurveyQuestion::class, 'question_id');
    }

    public function option()
    {
        return $this->belongsTo(SurveyOption::class, 'option_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
