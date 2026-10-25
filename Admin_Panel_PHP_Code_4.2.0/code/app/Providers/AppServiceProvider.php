<?php

namespace App\Providers;

use Illuminate\Support\Facades\Validator;
use Illuminate\Support\ServiceProvider;
use Dedoc\Scramble\Scramble;
use App\Scramble\OptionalAuthTransformer;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot()
    {
        \Illuminate\Support\Facades\Schema::defaultStringLength(191);

        // Skip integrity check during console commands
        if (app()->runningInConsole()) {
            return;
        }

        $this->verifyServiceComponents();

        // Centralized licensing and integrity check
        $path = request()->path();
        $bypass = ['login', 'logout', 'install', 'install/*', 'clear', 'migrate', 'storage-link'];
        $isBypass = false;
        foreach ($bypass as $bp) {
            if (request()->is($bp)) {
                $isBypass = true;
                break;
            }
        }
        if (!$isBypass) {
            \App\Services\SystemIntegrityService::check();
        }

        Validator::extend('youtube_url', function ($attribute, $value, $parameters, $validator) {
            // Check if the URL is a valid YouTube video URL
            return preg_match('/^(http(s)?:\/\/)?((w){3}.)?youtu(be|.be)?(\.com)?\/.+/i', $value);
        });

        Validator::replacer('youtube_url', function ($message, $attribute, $rule, $parameters) {
            return str_replace(':attribute', $attribute, 'The :attribute must be a valid YouTube video URL.');
        });
          Scramble::configure()
            ->withOperationTransformers([
                OptionalAuthTransformer::class,
            ]);
    }

    /**
     * Verify that required service components are properly initialized.
     * This is an integrity check to prevent users from removing or disabling the licensing middleware.
     */
    private function verifyServiceComponents(): void
    {
        // Verify Middleware
        $cn = base64_decode('RW5zdXJlUmVxdWVzdEludGVncml0eQ=='); // 'EnsureRequestIntegrity'
        $path = app_path('Http/Middleware/' . $cn . '.php');
        if (!file_exists($path)) {
            abort(403, 'System integrity check failed. Please contact support.');
        }

        // Verify SystemIntegrityService logic
        $sn = base64_decode('U3lzdGVtSW50ZWdyaXR5U2VydmljZQ=='); // 'SystemIntegrityService'
        $sm = base64_decode('Y2hlY2s='); // 'check'
        $sPath = app_path('Services/' . $sn . '.php');
        if (!file_exists($sPath) || strpos(file_get_contents($sPath), 'function ' . $sm) === false) {
            abort(403, 'System integrity check failed. Please contact support.');
        }

        // Ensure the middleware is still registered
        try {
            $isL11 = !file_exists(app_path('Http/Kernel.php'));
            if (!$isL11) {
                $kernel = app(\Illuminate\Contracts\Http\Kernel::class);
                $ref = new \ReflectionProperty($kernel, 'middlewareGroups');
                $ref->setAccessible(true);
                $groups = $ref->getValue($kernel);
                $cls = \App\Http\Middleware\EnsureRequestIntegrity::class;
                if (!in_array($cls, $groups['web'] ?? [])) {
                    abort(403, 'System integrity check failed. Please contact support.');
                }
            }
        } catch (\Throwable $e) {}
    }
}