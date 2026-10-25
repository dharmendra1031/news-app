<?php

namespace App\Http\Controllers;

use App\Models\Language;
use App\Models\SurveyOption;
use App\Models\SurveyQuestion;
use App\Models\SurveyResult;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use App\Services\ValidationService;

class SurveyController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['survey-list', 'survey-create', 'survey-edit', 'survey-delete']);
        try {
            $languageList = Language::where('status', 1)->get();
            return view('survey', compact('languageList'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "SurveyController -> index");
        }
    }

    public function store(Request $request)
    {
        ResponseService::noPermissionThenRedirect('survey-create');
        try{
            $validator = Validator::make($request->all(), [
                'question' => 'required|string|max:255',
                'language' => 'required|exists:tbl_languages,id',
                'option.*' => 'required|string|max:255',
            ]);
            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first());
            }

           $question = SurveyQuestion::create([
                'question'    => $request->question,
                'language_id' => $request->language,
                'status'      => 1,
            ]);

            $optionsData = [];

            foreach ($request->options as $row) {
                $optionsData[] = [
                    'question_id' => $question->id,
                    'options'     => $row['option'],
                    'counter'     => 0,
                    'created_at'  => now(),
                    'updated_at'  => now(),
                ];
            }

            SurveyOption::insert($optionsData);
            return ResponseService::successResponse(__('created_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, 'SurveyController -> store');
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('survey-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = SurveyQuestion::with('language')->withCount('surveyResult');
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->orWhere('id', 'LIKE', "%{$search}%")->orWhere('question', 'LIKE', "%{$search}%");
            });
        }
        if (isset($request->language_id)) {
            $sql = $sql->where('language_id', $request->language_id);
        }
        if (isset($request->status)) {
            $sql->where('status', $request->status);
        }
        $total = $sql->count('id');
        $sql = $sql->skip($offset)->take($limit)->orderBy($sort, $order);
        $rows = $sql->get()->map(function ($row) {
            $view = '';
            if (auth()->user()->can('survey-view')) {
                $view = '<a class="dropdown-item" href=' . url('survey_options', ['id' => $row->id]) . '  data-id="' . $row->id . '" title="View"><i class="fa fa-eye mr-1 text-primary"></i> View</a>';
            }
            $edit = '';
            if (auth()->user()->can('survey-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="'.__('edit').'"><i class="fa fa-pen mr-1 text-primary"></i>'.__('edit').'</a>';
            }
            $delete = '';
            if (auth()->user()->can('survey-delete')) {
                $delete = '<a data-url="' . url('survey', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="'.__('delete').'"><i class="fa fa-trash mr-1 text-danger"></i>'.__('delete').'</a>';
            }
            $operate = '';
            if (auth()->user()->can('survey-view') || auth()->user()->can('survey-edit') || auth()->user()->can('survey-delete')) {
                $operate =
                '<div class="dropdown">
                            <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" data-boundary="window" data-container="body">
                                <button class="btn btn-primary btn-sm px-3 operatebtn"><i class="fas fa-ellipsis-v"></i></button>
                            </a>
                            <div class="dropdown-menu dropdown-scrollbar" aria-labelledby="dropdownMenuButton">
                            ' .
                $view .
                $edit .
                $delete .
                '
                            </div>
                        </div>';
            }
            return [
                'row' => $row,
                'id' => $row->id,
                'language_id' => $row->language_id,
                'language_name' => $row->language->language ?? '',
                'question' => $row->question,
                'status' => $row->status,
                'status_badge' => $row->status == 1 ? '<span class="badge badge-success">'.__('active').'</span>' : '<span class="badge badge-danger">'.__('deactive').'</span>',
                'counter' => $row->survey_result_count,
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
        ResponseService::noPermissionThenRedirect('survey-edit');
        try{
            $validator = Validator::make($request->all(), [
                'question' => 'required|string|max:255',
                'language' => 'required|exists:tbl_languages,id',
            ]);
            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first());
            }
            SurveyQuestion::where('id', $request->edit_id)->update([
                'language_id' => $request->language,
                'question' => $request->question,
                'status' => $request->status,
            ]);

            return ResponseService::successResponse(__('updated_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, 'SurveyController -> update');
        }
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('survey-delete');
        try{
            $survey = SurveyQuestion::find($id);
            $survey->SurveyOptions()->delete();
            $survey->surveyResult()->delete();
            $survey->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, 'SurveyController -> destroy');
        }
    }

    public function get_survey_option($id)
    {
        ResponseService::noPermissionThenRedirect('survey-view');
        $question = SurveyQuestion::find($id);
        $options = SurveyOption::where('question_id', $id)->get();
        return view('survey-option', compact('options', 'question', 'id'));
    }

    public function store_option(Request $request)
    {
        try{
            $validator = Validator::make($request->all(), [
                'question_id' => 'required',
                'options.*' => 'required',
            ]);
            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first());
            }
            $question_id = $request->question_id;
            $options = $request->options;
            foreach ($options as $row) {
                SurveyOption::create([
                    'question_id' => $question_id,
                    'options' => $row['option'],
                    'counter' => 0,
                ]);
            }

            return ResponseService::successResponse(__('created_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, 'SurveyController -> store_option');
        }
    }

    public function survey_options_show(Request $request)
    {
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = SurveyOption::withCount('result')->where('question_id', $request->question_id);
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")->orwhere('options', 'LIKE', "%{$search}%");
            });
        }
        $total = $sql->count('id');
        $sql = $sql->skip($offset)->take($limit)->orderBy($sort, $order);
        $rows = $sql->get()->map(function ($row) {
            $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="'.__('edit').'"><i class="fa fa-pen mr-1 text-primary"></i>'.__('edit').'</a>';
            $delete = '<a data-url="' . route('survey-options-delete', $row->id) . '" class="dropdown-item survey-options-delete-form" data-id="' . $row->id . '" title="'.__('delete').'"><i class="fa fa-trash mr-1 text-danger"></i>'.__('delete').'</a>';
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

            $total_user = SurveyResult::where('question_id', $row->question_id)->count();
            $per = 0;
            if ($total_user) {
                $per = ($row->result_count * 100) / $total_user;
            }
            return [
                'row' => $row,
                'id' => $row->id,
                'question_id' => $row->question_id,
                'options' => $row->options,
                'percentage' => $per ? round($per, 2) . ' %' : '0 %',
                'counter' => $row->result_count,
                'operate' => $operate,
            ];
        });
        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function update_option(Request $request)
    {
        try {
            $option = SurveyOption::find($request->edit_id);

            if (!$option) {
                return ResponseService::errorResponse(__('Option Not Found'));
            }

            $option->update([
                'options' => $request->option,
                'counter' => 0,
            ]);

            return ResponseService::successResponse(__('updated_success'));

        } catch (\Exception $e) {
            return ResponseService::logErrorResponse($e, 'SurveyController -> update_option');
        }
    }

    public function delete_option(string $id, Request $request)
    {
        DB::beginTransaction();

        try {
            $option = SurveyOption::find($id);

            if (!$option) {
                DB::rollBack();
                return ResponseService::errorResponse(__('Option Not Found'));
            }

            SurveyResult::where([
                'option_id'   => $option->id,
                'question_id' => $option->question_id
            ])->delete();

            $option->delete();

            DB::commit();

            return ResponseService::successResponse(__('deleted_success'));

        } catch (Exception $e) {
            DB::rollBack();
            return ResponseService::logErrorResponse($e, 'SurveyController -> delete_option');
        }
    }

    public function bulkSurveyDelete(Request $request)
    {
        ResponseService::noPermissionThenRedirect('survey-delete');
        $validator = ValidationService::bulkDeleteValidator($request,'tbl_survey_question');
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
        DB::beginTransaction();
        try {

            $ids = $request->input('request_ids', []);

            if (empty($ids)) {
                return ResponseService::errorResponse(__('No Data Found'));
            }

            $surveyQuestions = SurveyQuestion::whereIn('id', $ids)->get();

            foreach ($surveyQuestions as $surveyQuestion) {
                $surveyQuestion->surveyOptions()->delete();
                $surveyQuestion->surveyResult()->delete();
            }

            SurveyQuestion::whereIn('id', $ids)->delete();
            DB::commit();

            return ResponseService::successResponse(__('deleted_success'));
        } catch (Exception $e) {
            DB::rollBack();
            return ResponseService::logErrorResponse($e, 'SurveyController -> bulk_survey_delete');
        }
    }
}
