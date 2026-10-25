<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SanitizeInput
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next)
    {
        $input = $request->all();

        $cleaned = $this->cleanArray($input);

        // Merge sanitized data back into request
        $request->merge($cleaned);

        return $next($request);
    }
     /**
     * Recursively sanitize all string values in the given array.
     */
    protected function cleanArray(array $array): array
    {
        // Excluded fields from sanitization (fields that should preserve HTML)
        $excluded = ['page_content', 'description', 'des', 'content_value', 'google_adsense'];

        foreach ($array as $key => $value) {
            if (is_string($value) && !in_array($key, $excluded)) {
                // Remove all HTML tags and trim spaces
                $array[$key] = strip_tags(trim($value));
            } elseif (is_array($value)) {
                // Handle nested arrays (e.g. multi-dimensional inputs)
                $array[$key] = $this->cleanArray($value);
            }
        }

        return $array;
    }
}
