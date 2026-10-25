<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\SurveyOption;

class SurveyQuestion extends Model
{
    use HasFactory;
    
    protected $table = 'tbl_survey_question';

    protected $fillable = ['language_id', 'question', 'status'];

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function surveyOptions()
    {
        return $this->hasMany(SurveyOption::class, 'question_id'); // Specify the foreign key column name
    }

    public function surveyResult()
    {
        return $this->hasMany(SurveyResult::class, 'question_id'); // Specify the foreign key column name
    }
}
