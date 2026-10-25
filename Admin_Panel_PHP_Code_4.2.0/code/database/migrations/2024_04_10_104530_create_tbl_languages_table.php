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
        Schema::create('tbl_languages', function (Blueprint $table) {
            $table->id();
            $table->string('language', 255);
            $table->string('code', 10)->index('code');
            $table->tinyInteger('status')->default(0)->comment('1-active, 0-deactive');
            $table->tinyInteger('isRTL')->default(0)->comment('1-yes, 0-no');
            $table->string('image')->nullable();
            $table->string('display_name')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_languages');
    }
};
