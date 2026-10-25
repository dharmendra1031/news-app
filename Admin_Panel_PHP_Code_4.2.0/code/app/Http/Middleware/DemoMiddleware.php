<?php

namespace App\Http\Middleware;

use Closure;
// use Illuminate\Console\View\Components\Alert;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Alert;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class DemoMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param \Illuminate\Http\Request $request
     * @param \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\JsonResponse
     */
    public function handle(Request $request, Closure $next)
    {
        $exclude_uri = [
            '/authenticate',
            '/get_category_by_language',
            '/get_subcategory_by_category',
            '/get_tag_by_language',
            '/get_feature_section_by_language',
            '/get_news_by_category',
            '/get_news_by_subcategory',
            '/get_featured_sections_by_language',
            '/get_custom_news',
            '/get_categories_tree',
            '/get-slug'

        ];
        $allowedUserId = env('DEMO_ALLOWED_USER');

        if (env('DEMO_MODE')) {
            if (Auth::check() && Auth::id() == $allowedUserId) {
                return $next($request);
            }
        }
        if (env('DEMO_MODE')) {
            if (!$request->isMethod('get') && !in_array($request->getRequestUri(), $exclude_uri)) {
                if ($request->ajax()) {
                    $response['error'] = true;
                    $response['message'] = 'This is not allowed in the Demo Version';
                    return response()->json($response);
                } elseif (request()->wantsJson() || Str::startsWith(request()->path(), 'api')) {
                    $response['error'] = true;
                    $response['message'] = 'This is not allowed in the Demo Version';
                    return response()->json($response);
                } else {
                    return back()->with('error', 'This is not allowed in the Demo Version');
                }
            }
        }
        return $next($request);
    }
}
