import $ from 'jquery'

$(document).ready(function () {
  if ($('#ErrorsProduct') == 'nul') {
    $('#single-product-create-modal').modal('show')
  }
}, 5000);

$(document).on('turbolinks:load', function () {

  $('input, select').on('click', function () {
    var name = this.name
    if (name.includes('product')) {
      $(this).removeClass('border-danger');
    }
  })
  // Product Create Form JQuery start
  $('.multi_basic_info_button').on('click', function () {
    // var photo = $('#multi-product-create-modal input[name="product[photo]"]').val()
    var title = $('#multi-product-create-modal input[name="product[title]"]').val()
    var sku = $('#multi-product-create-modal input[name="product[sku]"]').val()
    var category = $('#multi-product-create-modal select[name="product[category_id]"]').val()
    // var product_type = $('#multi-product-create-modal select[name="product[product_type]"').val()
    if ((title != "") && (sku != "") && (category != "")) {
      $('.multi-basic-info-form').addClass('d-none')
      $('.multi-detail-form').removeClass('d-none')
    }
    else {
      if (title == "") {
        $('#multi-product-create-modal input[name="product[title]"]').addClass('border border-danger');
      }
      if (sku == "") {
        $('#multi-product-create-modal input[name="product[sku]"]').addClass('border border-danger');
      }
      if (category == "") {
        $('#multi-product-create-modal #product_category_id_chosen').css({ 'border': '1px solid red', 'border-radius': '6px' });
      }
    }
  })

  $('.multi_detail_info_button').on('click', function () {
    $('.multi-detail-form').addClass('d-none')
    $('.multi-basic-info-form').removeClass('d-none')
  })

  $('.basic_info_button').on('click', function () {
    // var photo = $('input[name="product[photo]"]').val()
    var title = $('input[name="product[title]"]').val()
    var sku = $('input[name="product[sku]"]').val()
    var category = $('select[name="product[category_id]"]').val()
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
        $('#single-product-create-modal #product_category_id_chosen').css({ 'border': '1px solid red', 'border-radius': '6px' });
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

})
