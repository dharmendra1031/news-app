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
        Schema::create('tbl_users', function (Blueprint $table) {
            $table->id();
            $table->string('firebase_id');
            $table->string('name')->nullable();
            $table->string('type', 10)->nullable();
            $table->string('email')->nullable();
            $table->string('mobile', 20)->nullable();
            $table->text('profile')->nullable();
            $table->text('fcm_id');
            $table->tinyInteger('status')->default(0)->comment('1-active, 0-deactive');
            $table->dateTime('date');
            $table->integer('role');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_users');
    }
};
