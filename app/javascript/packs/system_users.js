import $ from 'jquery'

$(document).on('turbolinks:load', function () {
$('#system_user_payment_method').on('change', function () {
  var value = this.value
  if (value == 'credit'){
    $('.payment_method_field').removeClass('d-none')
  }
  else {
    $('.payment_method_field').addClass('d-none')
  }
})

$('.supplier-create').on('click', function () {
  $('.supplier-submit').trigger('click')
})
})