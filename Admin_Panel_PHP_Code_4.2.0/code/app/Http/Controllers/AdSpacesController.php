<?php

namespace App\Http\Controllers;

use App\Models\AdSpaces;
use App\Models\FeaturedSections;
use App\Models\Language;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use App\Services\ValidationService;

class AdSpacesController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['ad-space-list', 'ad-space-create', 'ad-space-edit', 'ad-space-delete']);
        try {
            $languageList = Language::where('status', 1)->get();
            return view('ad-spaces', compact('languageList'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "AdSpacesController -> index");
        }
    }

    public function store(Request $request)
    {
        ResponseService::noPermissionThenRedirect('ad-space-create');
        try {
            $validator = Validator::make($request->all(), [
                'language_id' => 'required|exists:tbl_languages,id,status,1',
                'page' => 'required|in:' . implode(',', AdSpaces::getPagesForPlatform($request->platform ?? '')),
                'platform' => 'required|in:app,web',
                'placement' => 'required|in:' . implode(',', AdSpaces::getPlacements($request->page ?? '', $request->platform ?? '')),
                'banner_type' => 'required|in:external_link,banner_only',
                'duration_days' => 'required|integer|min:1',
                'featured_section_id' => 'nullable|integer|exists:tbl_featured_sections,id',
                'ad_image' => 'required|image|mimes:jpg,png,jpeg,gif,svg,webp|max:2048',// 2MB
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $adSpaces = new AdSpaces();
            // platform wise image upload columns handling
            $bannerImage = $request->hasFile('ad_image') ? compressAndUpload($request->file('ad_image'), 'ad_spaces') : null;

            if ($request->platform == 'app') {
                $adSpaces->ad_image = $bannerImage;
                $adSpaces->web_ad_image = '';
            } elseif ($request->platform == 'web') {
                $adSpaces->web_ad_image = $bannerImage;
                $adSpaces->ad_image = '';
            }

            $placement = $request->placement;
            $ad_featured_section_id = $request->page == 'featured_section' ? ($request->featured_section_id ?? 0) : 0;

            $durationDays = (int) $request->duration_days;
            $adSpaces->language_id = $request->language_id;
            $adSpaces->page = $request->page;
            $adSpaces->platform = $request->platform;
            $adSpaces->placement = $placement;
            // $adSpaces->ad_space = $placement; // legacy backward compat
            $adSpaces->ad_featured_section_id = $ad_featured_section_id;
            $adSpaces->ad_type = $request->banner_type;
            $adSpaces->ad_url = $request->banner_type === 'external_link' ? ($request->ad_url ?? '') : '';
            $adSpaces->duration_days = $durationDays;
            $adSpaces->start_date = now()->toDateString();
            $adSpaces->end_date = now()->addDays($durationDays)->toDateString();
            $adSpaces->save();

            return ResponseService::successResponse(__('created_success'));
        } catch (Exception $e) {
            return ResponseService::errorResponse($e->getMessage());
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect(['ad-space-list']);

        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = AdSpaces::with(['language', 'feature_section']);

        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->orWhere('id', 'LIKE', "%{$search}%")->orWhere('ad_space', 'LIKE', "%{$search}%");
            });
        }
        if ($request->has('language_id') && $request->language_id) {
            $sql = $sql->where('language_id', $request->language_id);
        }
        if ($request->has('status') && $request->status != '') {
            $sql->where('status', $request->status);
        }
        if ($request->has('platform') && $request->platform != '') {
            $sql->where('platform', $request->platform);
        }
        $total = $sql->count('id');
        $sql = $sql->skip($offset)->take($limit)->orderBy($sort, $order);
        $rows = $sql->get()->map(function ($row) {
            $edit = '';
            if (auth()->user()->can('ad-space-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            $delete = '';
            if (auth()->user()->can('ad-space-delete')) {
                $delete = '<a data-url="' . url('ad_spaces', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }
            $operate = '';
            if ($edit == '' && $delete == '') {
                $operate = '-';
            } else {
                $operate =
                '<div class="dropdown">
                            <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                                <button class="btn btn-primary btn-sm px-3 operatebtn"><i class="fas fa-ellipsis-v"></i></button>
                            </a>
                            <div class="dropdown-menu dropdown-scrollbar" aria-labelledby="dropdownMenuButton">
                            ' .
                $edit .
                $delete .
                '
                            </div>
                        </div>';
            }

            $platformImage = $row->platform === 'web' ? $row->web_ad_image : $row->ad_image;

            return [
                'id' => $row->id,
                'language_id' => $row->language_id,
                'language' => $row->language->language ?? '',
                'date' => date('d-m-Y H:i:s', strtotime($row->created_at)),
                'page' => $row->page ?? '',
                'platform' => $row->platform ?? '',
                'placement' => $row->placement ?? '',
                'ad_featured_section_id' => $row->ad_featured_section_id ?? '',
                'ad_featured_section' => !empty($row->feature_section->title) ? 'Above ' . $row->feature_section->title : '',
                'banner_type' => $row->ad_type ?? 'external_link',
                'duration_days' => $row->duration_days ?? 1,
                'end_date' => $row->end_date,
                'ad_image' => $platformImage ?: '',
                'ad_url' => $row->ad_url ?? '',
                'status' => $row->status,
                'operate' => $operate,
            ];
        });
        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function update(Request $request)
    {
        ResponseService::noPermissionThenRedirect('ad-space-edit');
        try {
            $validator = Validator::make($request->all(), [
                'language_id' => 'required',
                'platform' => 'required|in:app,web',
                'page' => 'required|in:' . implode(',', AdSpaces::getPagesForPlatform($request->platform ?? '')),
                'placement' => 'required|in:' . implode(',', AdSpaces::getPlacements($request->page ?? '', $request->platform ?? '')),
                'banner_type' => 'required|in:external_link,banner_only',
                'duration_days' => 'required|integer|min:1',
                'featured_section_id' => 'nullable|integer|exists:tbl_featured_sections,id',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $adSpaces = AdSpaces::find($request->edit_id);

            if ($request->hasFile('ad_image')) {
                $bannerImage = compressAndUpload($request->file('ad_image'), 'ad_spaces');
                if ($request->platform == 'app') {
                    $adSpaces->ad_image = $bannerImage;
                    $adSpaces->web_ad_image = '';
                } elseif ($request->platform == 'web') {
                    $adSpaces->web_ad_image = $bannerImage;
                    $adSpaces->ad_image = '';
                }
            } else {
                // No new upload — preserve existing raw paths
                $adSpaces->ad_image = $adSpaces->getRawOriginal('ad_image');
                $adSpaces->web_ad_image = $adSpaces->getRawOriginal('web_ad_image');
            }

            $placement = $request->placement;
            $ad_featured_section_id = $request->page == 'featured_section' ? ($request->featured_section_id ?? 0) : 0;

            $durationDays = (int) $request->duration_days;
            $adSpaces->language_id = $request->language_id;
            $adSpaces->page = $request->page;
            $adSpaces->platform = $request->platform;
            $adSpaces->placement = $placement;
            // $adSpaces->ad_space = $placement; // legacy backward compat
            $adSpaces->ad_featured_section_id = $ad_featured_section_id;
            $adSpaces->ad_type = $request->banner_type;
            $adSpaces->ad_url = $request->banner_type === 'external_link' ? ($request->ad_url ?? '') : '';
            $adSpaces->duration_days = $durationDays;
            $adSpaces->start_date = now()->toDateString();
            $adSpaces->end_date = now()->addDays($durationDays)->toDateString();
            $adSpaces->status = $request->status;
            $adSpaces->save();

            return ResponseService::successResponse(__('updated_success'));
        } catch (Exception $e) {
            return ResponseService::errorResponse($e->getMessage());
        }
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('ad-space-delete');
        try{
            $adSpace = AdSpaces::findOrFail($id);
            // images deleted from model

            $adSpace->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(Exception $e){
            return ResponseService::errorResponse($e->getMessage());
        }
    }

    public function getFeaturedSectionsByLanguage(Request $request)
    {
        try{

            $language_id = $request->language_id;
            $res = FeaturedSections::where('language_id', $language_id)->where('status', 1)->get();
            $option = '';
            if (!empty($res)) {
                foreach ($res as $value) {
                    if ($value['style_app'] == 'style_6' || $value['style_web'] == 'style_web') {
                        $option .= '<option value="'.$value['id'].'" >'.__('above'). ' ' . $value['title'] . '.  (' . __('not_applicable') . ')</option>';
                    } else {
                        $option .= '<option value="'.$value['id'].'">'.__('above') . ' ' . $value['title'] . '</option>';
                    }
                }
            }
            return $option;
        }catch(Exception $e){
            Log::error($e->getMessage());
            return '';
        }
    }
    public function bulkAdSpacesDelete(Request $request)
    {
        ResponseService::noPermissionThenRedirect('ad-space-delete');
        
         $validator = ValidationService::bulkDeleteValidator($request, 'tbl_ad_spaces');

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
        try {

            collect($request->request_ids)
                ->chunk(200)
                ->each(function ($chunkIds) {

                    // Get raw DB values without accessors
                    $records = AdSpaces::query()
                        ->whereIn('id', $chunkIds)
                        ->toBase()
                        ->get(['ad_image', 'web_ad_image']);

                    // Merge both image columns
                    $images = collect($records)
                        ->flatMap(function ($record) {
                            return [
                                $record->ad_image,
                                $record->web_ad_image
                            ];
                        })
                        ->filter()
                        ->unique()
                        ->values()
                        ->toArray();

                    // Delete all images
                    if (!empty($images)) {
                        Storage::disk('public')->delete($images);
                    }

                    // Delete rows
                    AdSpaces::whereIn('id', $chunkIds)->delete();
                });

            return ResponseService::successResponse(__('deleted_success'));

        } catch (Exception $e) {
            return ResponseService::errorResponse($e->getMessage());
        }
    }

}
