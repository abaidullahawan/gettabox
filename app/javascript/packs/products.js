import $ from 'jquery'

$(document).ready(function () {
  if ($('#ErrorsProduct') == 'nul') {
    $('#single-product-create-modal').modal('show')
  }
}, 5000);

$(document).on('turbolinks:load', function () {

  $('input, select').on('click', function () {
      $(this).removeClass('border-danger');
  })
  // Product Create Form JQuery start
  $('.multi_basic_info_button').on('click', function () {
    // var photo = $('#multi-product-create-modal input[name="product[photo]"]').val()
    var title = $('#multi-product-create-modal input[name="product[title]"]').val()
    var sku = $('#multi-product-create-modal input[name="product[sku]"]').val()
    var category = $('#multi-product-create-modal input[name="category_name"]').val()
    // var product_type = $('#multi-product-create-modal select[name="product[product_type]"').val()
    if ((title != "") && (sku != "")) {
      $('.multi-basic-info-form').addClass('d-none')
      $('.multi-detail-form').removeClass('d-none')
      $('.create_product_button').removeClass('d-none')
    }
    else {
      if (title == "") {
        $('#multi-product-create-modal input[name="product[title]"]').addClass('border border-danger');
      }
      if (sku == "") {
        $('#multi-product-create-modal input[name="product[sku]"]').addClass('border border-danger');
      }
      // if (category == "") {
      //   $('#multi-product-create-modal input[name="category_name"]').addClass('border border-danger');
      // }
    }
  })

  $('.multi_detail_info_button').on('click', function () {
    $('.multi-detail-form').addClass('d-none')
    $('.multi-basic-info-form').removeClass('d-none')
    $('.create_product_button').addClass('d-none')
  })

  $('.basic_info_button').on('click', function () {
    // var photo = $('input[name="product[photo]"]').val()
    var title = $('input[name="product[title]"]').val()
    var sku = $('input[name="product[sku]"]').val()
    var category = $('input[name="category_name"]').val()
    // var product_type = $('select[name="product[product_type]"]').val()
    if ((title != "") && (sku != "") && (category != "")) {
      $('.basic-info-form').addClass('d-none')
      $('.detail-form').removeClass('d-none')
    }
    else {
      if (title == "") {
        $('#single-product-create-modal input[name="product[title]"]').addClass('border border-danger');
      }
      if (sku == "") {
        $('#single-product-create-modal input[name="product[sku]"]').addClass('border border-danger');
      }
      if (category == "") {
        $('#single-product-create-modal input[name="category_name"]').addClass('border border-danger');
      }
    }
  })

  $('.detail_button_previous').on('click', function () {
    $('.detail-form').addClass('d-none')
    $('.basic-info-form').removeClass('d-none')

  })

  $('.detail_button').on('click', function () {
    var length = $('input[name="product[length]"]').val()
    var width = $('input[name="product[width]"]').val()
    var height = $('input[name="product[height]"]').val()
    var weight = $('input[name="product[weight]"]').val()
    if ((length != "") && (width != "") && (height != "") && (weight != "")) {
      $('.detail-form').addClass('d-none')
      $('.stock-form').removeClass('d-none')
      $('.create_product_button').removeClass('d-none')
    }
    else {
      if (length == "") {
        $('input[name="product[length]"]').addClass('border border-danger');
      }
      if (width == "") {
        $('input[name="product[width]"]').addClass('border border-danger');
      }
      if (height == "") {
        $('input[name="product[height]"]').addClass('border border-danger');
      }
      if (weight == "") {
        $('input[name="product[weight]"]').addClass('border border-danger');
      }
    }
  })

  $('.stock_button_previous').on('click', function () {
    $('.stock-form').addClass('d-none')
    $('.detail-form').removeClass('d-none')
    $('.detail-tax-field').addClass('d-none')
  })

  $('.stock_button').on('click', function () {
    var total_stock = $('input[name="product[total_stock]"]').val()
    var vat = $('input[name="product[vat]"]').val()
    var supplier = $('select[name="product[product_suppliers_attributes][1][system_user_id]"]').val()
    if ((total_stock != "") && (vat != "") && (supplier != "")) {
      $('.stock-form').addClass('d-none')
      $('.extra-form').removeClass('d-none')
      $('.extra-stock-field').removeClass('d-none')
      $('.extra-pack-field').removeClass('d-none')
    }
    else {
      if (total_stock == "") {
        $('input[name="product[total_stock]"]').addClass('border border-danger');
      }
      if (vat == "") {
        $('input[name="product[vat]"]').addClass('border border-danger');
      }
      if (supplier == "") {
        $('select[name="product[product_suppliers_attributes][1][system_user_id]"]').addClass('border border-danger');
      }
    }
  })

  $('.stock_button_previous').on('click', function () {
    $('.stock-form').addClass('d-none')
    $('.detail-form').removeClass('d-none')
    $('.create_product_button').addClass('d-none')
  })

  $('.extra_button_previous').on('click', function () {
    $('.extra-form').addClass('d-none')
    $('.stock-form').removeClass('d-none')
  })

  $('.extra_feild').on('click', function(){
    $('.stock-form').addClass('d-none')
    $('.extra-field-form').removeClass('d-none')
    $('.create_product_button').removeClass('d-none')
  })


  $('.extra_button_previous').on('click', function(){
    var total_stock = $('input[name="product[total_stock]"]').val()
    var vat = $('input[name="product[vat]"]').val()
    var supplier = $('select[name="product[product_suppliers_attributes][1][system_user_id]"]').val()
    if ((total_stock != "") && (vat != "") && (supplier != "")) {
      $('.stock-form').removeClass('d-none')
      $('.extra-field-form').addClass('d-none')
      $('.create_product_button').addClass('d-none')
      $('.create_product_button').removeClass('d-none')
    }
    else {
      if (total_stock == "") {
        $('input[name="product[total_stock]"]').addClass('border border-danger');
      }
      if (vat == "") {
        $('input[name="product[vat]"]').addClass('border border-danger');
      }
      if (supplier == "") {
        $('select[name="product[product_suppliers_attributes][1][system_user_id]"]').addClass('border border-danger');
      }
    }
  })

  // $('#single-product-create-modal input[type="submit"]').on('click', function () {
  //   var season = $('select[name="product[season_id]"]').val()
  //   if ((season != "")) {
  //     $('.create-single-product').trigger('click')
  //   }
  //   else {
  //     if (season == "") {
  //       $('#single-product-create-modal #product_season_id_chosen').css({'border': '1px solid red', 'border-radius': '6px'});
  //     }
  //   }
  // })
  // Product Create Form JQuery end

  $(".nested_fields_btn").
    data("association-insertion-method", 'after')

  $('.product-type-field').on('change', function () {
    $('.product_type_submit').trigger('click')
  })

  $('.bulk-destroy-objects').on('click', function () {
    $('.bulk-method-destroy-objects').trigger('click')
  })

  window.update_selected = function (url, class_name, event) {
    var target = event.currentTarget
    var value = target.checked
    var id = target.id

    if (typeof class_name === 'string' && typeof value === 'boolean' && typeof id === 'string' && typeof url === 'string'){
      $.ajax({
        url: url,
        type: "GET",
        data: { 'selected': value, 'id': id, class_name: class_name },
        success: function (response) {
          if (response.result) {
            $('.jquery-selected-alert').html('Object updated successfully')
            $('.jquery-selected-alert').addClass('bg-success').removeClass('d-none').removeClass('bg-danger')
            $(".jquery-selected-alert").fadeTo(2000, 500).slideUp(500, function () {
              $(".jquery-selected-alert").slideUp(500);
            });
          }
          else{
            $('.jquery-selected-alert').html('Object cannot be updated! '+ response.errors[0])
            $('.jquery-selected-alert').addClass('bg-danger').removeClass('d-none')
            $('.jquery-selected-alert').alert('show')
            $(".jquery-selected-alert").fadeTo(2000, 500).slideUp(500, function () {
              $(".jquery-selected-alert").slideUp(500);
            });
          }
        }
      })
    }
    else {
      $('.jquery-selected-alert').html('Cannot update object, please refresh and try again.')
      $('.jquery-selected-alert').addClass('bg-danger').removeClass('d-none')
      $(".jquery-selected-alert").fadeTo(2000, 500).slideUp(500, function () {
        $(".jquery-selected-alert").slideUp(500);
      });
    }
  }

  window.bulk_update_selected = function (url, class_name, event) {
    var target = event.target
    var switches = $('input[name="select-switch"]');
    switches.prop("checked", target.checked);
    var selected = []
    var unselected = []
    switches.each(function () {
      if (this.checked) {
        selected.push(this.id)
      }
      else {
        unselected.push(this.id)
      }
    })

    if (typeof class_name === 'string' && (selected.length + unselected.length > 0) && typeof url === 'string') {
      $.ajax({
        url: url,
        type: 'GET',
        data: { 'selected': selected, 'unselected': unselected, class_name: class_name },
        success: function (response) {
          if (response.result) {
            $('.jquery-selected-alert').html('All objects updated successfully')
            $('.jquery-selected-alert').addClass('bg-success').removeClass('d-none').removeClass('bg-danger')
            $(".jquery-selected-alert").fadeTo(2000, 500).slideUp(500, function () {
              $(".jquery-selected-alert").slideUp(500);
            });
          }
        }
      })
    }
    else {
      $('.jquery-selected-alert').html('Cannot update object, please refresh and try again.')
      $('.jquery-selected-alert').addClass('bg-danger').removeClass('d-none')
      $(".jquery-selected-alert").fadeTo(2000, 500).slideUp(500, function () {
        $(".jquery-selected-alert").slideUp(500);
      });
    }
  }

  $('.reason-get-button').on('click', function () {
    $('.update_fake_stock').val($('.updating_fake_stock').val());
    $('.update_stock').val($('.updating_stock').val());
    $('.reason-modal').modal('show');
  })

})
