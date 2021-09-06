import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  $('.order_item_price').on('blur', function () {
    $('.supplier-submit').trigger('click')
  })
})