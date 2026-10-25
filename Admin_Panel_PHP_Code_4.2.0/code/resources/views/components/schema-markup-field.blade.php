@props([
    'id'    => 'schema_markup',
    'value' => '',
])

<label class="mr-2">{{ __('schema_markup') }}</label>
<i data-content="{{ __('schema_text') }}.<a href='https://www.rankranger.com/schema-markup-generator' target='_blank'>{{ __('rank_ranger_schema_markup_generator') }}</a>"
    class="fa fa-question-circle"></i>
<input type="text" name="schema_markup" id="{{ $id }}" class="form-control"
    placeholder="{{ __('schema_markup') }}" value="{{ $value }}">
