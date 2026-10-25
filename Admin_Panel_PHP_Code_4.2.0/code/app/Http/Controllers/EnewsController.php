<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Storage;
use App\Models\Enews;
use App\Models\Language;
use App\Services\BootstrapTableService;
use App\Services\ResponseService;
use App\Services\EnewsService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
// use Response;
use Illuminate\Support\Facades\Auth;
use App\Services\ValidationService;

class EnewsController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['enews-list', 'enews-create', 'enews-edit', 'enews-delete']);
        try{
            $languageList = Language::where('status', 1)->get();
            return view('enews.index', compact('languageList'));
        }catch(Exception $e){
            return ResponseService::logErrorRedirectResponse($e, "EnewsController -> index");
        }
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        try {
            ResponseService::noPermissionThenRedirect('enews-create');

            $validator = Validator::make($request->all(), EnewsService::getValidationRules());
            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first());
            }

            $slug = generateUniqueSlug($request->slug);
            $existingSlug = Enews::where('slug', $slug)->exists();
            if ($existingSlug) {
                // $response = [
                //     'error' => true,
                //     'message' => __('slug_already_use'),
                // ];
                // return response()->json($response);
                return ResponseService::errorResponse(__('slug_already_use'));
            }

            $enews = EnewsService::createEnews($request, $slug);

            return ResponseService::successResponse(__('created_success'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "EnewsController -> store");
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(Request $request)
    {
        ResponseService::noPermissionThenSendJson('enews-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');
        $search = $request->input('search', '');
        $languageId = $request->input('language_id', '');

        $sql = Enews::with('language')->safeOrder($sort, $order)->search($search, $languageId);
        if ($request->status !== null && $request->status !== '') {
            $sql->where('status', $request->status);
        }
        $total = $sql->count();
        $sql = $sql->orderBy($sort, $order)->skip($offset)->take($limit);

        $result = $sql->get();
        $bulkData = array();
        $bulkData['total'] = $total;
        $rows = array();
        $no = 1;
        $canEdit = Auth::user()->can('enews-edit');
        $canDelete = Auth::user()->can('enews-delete');

        foreach ($result as $row) {
            $tempRow = $row->toArray();
            $tempRow['no'] = $no++;
            $tempRow['language'] = $row?->language?->language ?? '';

            $tempRow['raw_status'] = $row->status;
            $tempRow['thumbnail'] = $row->thumbnail;
            // attachment is pdf file, so we need to show the pdf icon and click new tab open pdf file
            $tempRow['attachment'] = $row->attachment;
            $actions = [];

            if ($canEdit) {
                $actions[] = [
                    'text' => __('edit'),
                    'icon' => 'fa fa-pen text-primary',
                    'class' => 'edit-data',
                    'data-toggle' => 'modal',
                    'data-target' => '#editDataModal',
                ];
            }
            if ($canDelete) {
                $actions[] = [
                    'text' => __('delete'),
                    'icon' => 'fa fa-trash text-danger',
                    'class' => 'delete-form',
                    'data-url' => route('e-news.destroy', $row->id),
                    'data-id' => $row->id,
                    'data-title' => __('are_you_sure'),
                    'data-text' => __('deleting_a_e_news_it_will_breaks_relations_to_news_without_additional_confirmation'),
                ];
            }
            $operate = '';
            if (!empty($actions)) {
                $operate .= BootstrapTableService::dropdown(
                    'fa fa-ellipsis-v',
                    $actions,
                );
            }
            $tempRow['operate'] = $operate;
            $rows[] = $tempRow;
        }
        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {

        ResponseService::noPermissionThenRedirect('enews-edit');

        try {

            $validator = Validator::make($request->all(), EnewsService::getValidationRules(true));
            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first());
            }

            $enews = Enews::find($id);
            if(!$enews){
                return ResponseService::errorResponse(__('enews_not_found'));
            }

            $slug = generateUniqueSlug($request->slug);
            $existingSlug = Enews::where('slug', $slug)->where('id', '!=', $id)->exists();
            if ($existingSlug) {
                return ResponseService::errorResponse(__('slug_already_use'));
            }

            $enews = EnewsService::updateEnews($request, $slug, $id);

            return ResponseService::successResponse(__('updated_success'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "EnewsController -> update");
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        try{
            ResponseService::noPermissionThenSendJson('enews-delete');

            $eNews = Enews::find($id);
            if(!$eNews){
                return ResponseService::errorResponse(__('Data Not Found'));
            }
            // image and PDf are deleted in models
            EnewsService::deleteEnews($id);

            return ResponseService::successResponse(__('deleted_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "EnewsController -> destroy");
        }
    }
   public function bulkDeleteEnews(Request $request)
    {  
         ResponseService::noPermissionThenSendJson('enews-delete');

        $validator = ValidationService::bulkDeleteValidator($request, 'tbl_e_news');

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
        try {

            $request_ids = $request->request_ids;

            $records = Enews::query()
                ->whereIn('id', $request_ids)
                ->toBase()
                ->get(['thumbnail', 'attachment']);

            $files = collect($records)
                ->flatMap(function ($record) {
                    return [
                        $record->thumbnail,
                        $record->attachment,
                    ];
                })
                ->filter()
                ->unique()
                ->values()
                ->toArray();


            Enews::query()
                ->whereIn('id', $request_ids)
                ->toBase()
                ->delete();

            if (!empty($files)) {
                Storage::disk('public')->delete($files);
            }

            return ResponseService::successResponse(__('deleted_success'));

        } catch (Exception $e) {

            return ResponseService::logErrorResponse(
                $e,
                "EnewsController -> bulkDeleteEnews"
            );
        }
    }
}
