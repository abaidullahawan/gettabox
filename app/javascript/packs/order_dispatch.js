import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  $('.allocate-button').on('click', function () {
    $('.bulk-allocation').trigger('click')
  })

  $('.re-calculate-rules').on('click', function () {
    var object_ids = $('input[name="object_ids[]"]:checked')
    var order_ids = object_ids.map(function (i, e) { return e.value }).toArray();
    $.ajax({
      url: '/order_dispatches/recalculate_rule',
      type: 'GET',
      data: { 'orders': order_ids },
      success: function (response) {
        window.location.reload()
      }
    })
  })

  $('.tracking-form').on('submit', function(){
    $('.without_tracking_btn').removeClass('d-none')
  })

})
