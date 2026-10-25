<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;
use Illuminate\Http\Request;

class Authenticate extends Middleware
{
    /**
     * Get the path the user should be redirected to when they are not authenticated.
     */
    protected function redirectTo(Request $request): ?string
    {
        return $request->expectsJson() ? null : route('login');
    }

    protected function unauthenticated($request, array $guards)
    {
        if ($request->is('api/*')) {
            // For API requests
            abort(response()->json(['message' => 'Unauthenticated.', 'error' => true], 401));
        } else {
            // For other routes, e.g., admin panel
            abort(redirect('/login')); // Adjust the redirect URL as needed
        }
    }
}
