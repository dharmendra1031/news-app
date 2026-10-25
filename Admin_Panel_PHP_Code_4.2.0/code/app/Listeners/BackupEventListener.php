<?php

namespace App\Listeners;

use Spatie\Backup\Events\BackupZipWasCreated;

class BackupEventListener
{
    /**
     * The generated custom file name.
     *
     * @var string|null
     */
    protected static $customFileName;

    /**
     * Handle the event.
     *
     * @param  BackupZipWasCreated  $event
     * @return void
     */
    public function handle(BackupZipWasCreated $event)
    {
        // Set the custom file name in the config
        config(['custom_backup_filename' => $this->generateCustomFileName()]);

        // Log the generated file name
        \Log::info("Custom backup file name: " . config('custom_backup_filename'));
    }

    /**
     * Generate a custom file name for the backup.
     *
     * @return string
     */
    protected function generateCustomFileName()
    {
        // Customize the file name format as needed
        return 'custom_backup_' . now()->format('YmdHis') . '.zip';
    }
}
