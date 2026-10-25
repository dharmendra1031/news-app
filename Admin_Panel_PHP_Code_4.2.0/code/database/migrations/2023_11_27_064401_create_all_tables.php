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
        if (!Schema::hasTable('tbl_user_roles')) {
            Schema::create('tbl_user_roles', function (Blueprint $table) {
                $table->id();
                $table->string('role')->nullable();
                $table->timestamps();
            });
        } else {
            Schema::table('tbl_user_roles', function (Blueprint $table) {
                if (!Schema::hasColumn('tbl_user_roles', 'created_at')) {
                    $table->timestamps();
                }
            });
        }
    }
    public function down(): void
    {
        Schema::dropIfExists('tbl_user_roles');
    }
};
