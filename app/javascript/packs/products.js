import $ from 'jquery'

$(document).on('turbolinks:load', function () {
$('.bulk-delete-products').on('click', function () {
  debugger;
  $('.bulk-method-products').trigger('click')
})

$('.select-all-products').on("click", function(){
  debugger;
  var cbxs = $('input[name="product_ids[]"]');
  cbxs.prop("checked", !cbxs.prop("checked"));
});
})