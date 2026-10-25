<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tbl_survey_result', function (Blueprint $table) {
            $table->id();
            $table->integer('question_id')->index('question_id');
            $table->integer('option_id')->index('option_id');
            $table->integer('user_id')->index('user_id');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_survey_result');
    }
};
