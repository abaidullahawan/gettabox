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

  $('#supplier-name-search').on('keyup', function () {
    var supplier_name = this.value
    $(".supplier-name-dropdown-list").show()
    $.ajax({
      url: "/system_users/system_user_by_name",
      type: "POST",
      data: { 'supplier_name': supplier_name },
      success: function(response) {
        $(".supplier-name-list-item").remove()
        if(response.length == 0) {
          $(".supplier-name-dropdown-list").append('<li><a href="#" class="dropdown-item supplier-name-list-item">No result found</a></li>')
        }
        else {
          $.each(response,function() {
            $(".supplier-name-dropdown-list").append('<li><a href="#" class="dropdown-item supplier-name-list-item">'+ this.name +'</a></li>')
          });
        }
      }
    })
  })

  $('.supplier-name-dropdown-list').on('click', '.supplier-name-list-item', function () {
    $('#supplier-name-search').val(this.outerText)
    $('#system_user_search').submit();
  })

  $('#supplier-name-search').on('blur', function () {
    $(".supplier-name-dropdown-list").hide()
  })

})
