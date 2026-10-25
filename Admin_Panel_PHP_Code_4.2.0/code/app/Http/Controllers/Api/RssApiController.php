<?php

namespace App\Http\Controllers\Api;

use App\Models\Category;
use App\Models\RSS;
use App\Models\SubCategory;
use App\Models\Tag;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RssApiController extends BaseApiController
{
    // -------------------------------------------------------------------------
    // RSS Feeds
    // -------------------------------------------------------------------------


    public function getRssFeed(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code'    => 'required|string|exists:tbl_languages,code',
                'category_id'      => 'nullable|numeric|exists:tbl_category,id',
                'category_slug'    => 'nullable|string|max:255',
                'subcategory_id'   => 'nullable|numeric|exists:tbl_subcategory,id',
                'subcategory_slug' => 'nullable|string|max:255',
                'tag_id'           => 'nullable|numeric|exists:tbl_tag,id',
                'tag_slug'         => 'nullable|string|max:255',
                'search'           => 'nullable|string|max:255',
                'offset'           => 'nullable|integer|min:0',
                'limit'            => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $request['get_user_news'] = $request->get_user_news ?? 0;
            $language_id              = $this->resolveLanguageId($request);
            $offset                   = $request->offset ?? 0;
            $limit                    = $request->limit ?? 10;

            $rss = RSS::with(
                'category:id,category_name,slug',
                'sub_category:id,subcategory_name'
            )->where('language_id', $language_id)->where('status', 1);

            if ($request->category_id) {
                $rss->where('category_id', $request->category_id);
            }
            if ($request->category_slug) {
                $category_id = Category::select('id')->where('slug', $request->category_slug)->pluck('id')->first();
                $rss->where('category_id', $category_id);
            }
            if ($request->subcategory_id) {
                $rss->where('subcategory_id', $request->subcategory_id);
            }
            if ($request->subcategory_slug) {
                $subcategory_id = SubCategory::select('id')->where('slug', $request->subcategory_slug)->pluck('id')->first();
                $rss->where('subcategory_id', $subcategory_id);
            }
            if ($request->tag_id) {
                $rss->whereRaw('FIND_IN_SET(?, tag_id)', [$request->tag_id]);
            }
            if ($request->tag_slug) {
                $tag_id = Tag::select('id')->where('slug', $request->tag_slug)->pluck('id')->first();
                $rss->whereRaw('FIND_IN_SET(?, tag_id)', [$tag_id]);
            }
            if ($request->search) {
                $search = $request->search;
                $rss->where(fn($q) => $q->where('tbl_rss.feed_name', 'LIKE', "%{$search}%"));
            }

            $rss->select('tbl_rss.*')->orderBy('tbl_rss.id', 'DESC');

            $total = $rss->clone()->count();

            if (!$total) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $res = $rss->clone()->skip($offset)->take($limit)->get();
            $res->each(function ($item) {
                $item->tag = [];
                if (isset($item->tag_id) && $item->tag_id != '') {
                    $item->tag_name = Tag::whereIn('id', explode(',', $item->tag_id))->distinct()->pluck('tag_name')->implode(',');
                    $item->tag      = Tag::select('id', 'tag_name', 'slug')->whereIn('id', explode(',', $item->tag_id))->get();
                }
            });

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $res,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'RssApiController -> getRssFeed');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }
}
