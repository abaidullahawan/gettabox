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

  $('.payment-method-field').on('change', function () {
    $('.payment-method-button').trigger('click')
  })

  $('.supplier-name-dropdown-list').on('click', '.supplier-name-list-item', function () {
    $('#supplier-name-search').val(this.outerText)
    $('.supplier-name-dropdown-list').hide();
    $('#supplier-name-search').focus();
    return false
  })

  $('.supplier-name-dropdown-list').on('focus', '.supplier-name-list-item', function () {
    $('#supplier-name-search').val(this.outerText)
  })

})
