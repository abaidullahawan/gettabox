$(document).on('turbolinks:load', function () {
  $('.chosen-select').chosen({
    allow_single_deselect: true,
    placeholder_text_single: 'Select/Search an Option',
    no_results_text: 'No results matched',
    width: '100%'
  }, 100);

})