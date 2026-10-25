<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\BaseApiController;
use App\Models\SurveyOption;
use App\Models\SurveyQuestion;
use App\Models\SurveyResult;
use App\Services\ResponseService;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class SurveyApiController extends BaseApiController
{
    public function getQuestion(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $languageId          = $this->resolveLanguageId($request);
            $user_id             = Auth::user()->id;
            $answeredQuestionIds = SurveyResult::where('user_id', $user_id)->pluck('question_id')->toArray();

            $data = SurveyQuestion::select('id', 'question', 'status', 'language_id')
                ->with('surveyOptions:id,options,counter,question_id')
                ->where(['status' => 1, 'language_id' => $languageId]);

            if (!empty($answeredQuestionIds)) {
                $data->whereNotIn('id', $answeredQuestionIds);
            }

            $total = $data->clone()->count('id');
            if ($total == 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NO_DATA_FOUND'), null);
            }

            $offset = $request->offset ?? 0;
            $limit  = $request->limit ?? 10;
            $res    = $data->clone()->orderByDesc('id')->limit($limit)->offset($offset)->get();

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $res,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SurveyApiController -> getQuestion');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function getQuestionResult(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'question_id'   => 'nullable|numeric|exists:tbl_survey_question,id',
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $languageId          = $this->resolveLanguageId($request);
            $offset              = $request->offset ?? 0;
            $limit               = $request->limit ?? 10;
            $user_id             = Auth::user()->id;
            $answeredQuestionIds = SurveyResult::where('user_id', $user_id)->pluck('question_id')->toArray();

            $res = SurveyQuestion::with(['surveyOptions'])->withCount('surveyResult')
                ->where(function ($q) use ($languageId, $answeredQuestionIds, $request) {
                    $q->where('status', '1')->where('language_id', $languageId);
                    if (!empty($answeredQuestionIds)) {
                        $q->whereNotIn('id', $answeredQuestionIds);
                    }
                    if ($request->has('question_id')) {
                        $q->where('id', $request->question_id);
                    }
                });

            $total = $res->clone()->count();
            if ($total == 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NO_DATA_FOUND'), null);
            }

            $questions = $res->clone()->orderByDesc('id')->limit($limit)->offset($offset)->get();

            foreach ($questions as $row) {
                $totalUserResponses = SurveyResult::where('question_id', $row->id)->count();
                $row->load(['surveyOptions' => fn($q) => $q->withCount('result')]);
                $row->surveyOptions->each(function ($option) use ($totalUserResponses) {
                    $option->percentage = $totalUserResponses != 0
                        ? ($option->result_count * 100) / $totalUserResponses
                        : 0;
                });
            }

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $questions,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SurveyApiController -> getQuestionResult');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function setQuestionResult(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'question_id' => ['required', 'numeric', 'exists:tbl_survey_question,id'],
                'option_id'   => ['required', 'numeric', 'exists:tbl_survey_option,id'],
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $surveyResult = SurveyResult::create([
                'user_id'     => Auth::user()->id,
                'question_id' => $request->question_id,
                'option_id'   => $request->option_id,
            ]);

            $option          = SurveyOption::findOrFail($surveyResult->option_id);
            $option->counter = $option->counter + 1;
            $option->save();

            // return ResponseService::successResponse(__('Data inserted successfully'), $surveyResult);
        }catch(ModelNotFoundException $e){
            return ResponseService::errorResponse(__('Data not found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), $e);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SurveyApiController -> setQuestionResult');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }
}
