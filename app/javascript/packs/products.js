import $ from 'jquery'

$(document).on('turbolinks:load', function () {

  // Product Create Form JQuery start
  $('.basic_info_button').on('click', function () {
    debugger;
    var photo = $('input[name="product[photo]"]').val() || $('#multi-product-create-modal input[name="product[photo]"]').val()
    var title = $('input[name="product[title]"]').val() || $('#multi-product-create-modal input[name="product[title]"]').val()
    var sku = $('input[name="product[sku]"]').val() || $('#multi-product-create-modal input[name="product[sku]"]').val()
    var category = $('select[name="product[category_id]"]').val() || $('#multi-product-create-modal select[name="product[category_id]"]').val()
    var product_type = $('select[name="product[product_type]"]').val() || $('#multi-product-create-modal select[name="product[product_type]"').val()
    if ((photo != "") && (title != "") && (sku != "") && (category != "")) {
      $('.basic-info-form').addClass('d-none')
      $('.detail-form').removeClass('d-none')
    }
    else {
      if (photo == "") {
        alert("Please select a photo")
      }
      else if (title == "") {
        alert("Please Enter a Title")
      }
      else if (sku == "") {
        alert("Please Enter a SKU")
      }
      else if (category == "") {
        alert("Please select a category")
      }
    }
  })

  $('.detail_button_previous').on('click', function () {
    $('.detail-form').addClass('d-none')
    $('.basic-info-form').removeClass('d-none')
  })

  $('.detail_button').on('click', function () {
    debugger;
    if ((this.parentElement.parentElement.parentElement.parentElement.children[0].children[6].children[1].value) == "Multiple") {
      $('.detail-form').addClass('d-none')
      $('.extra-form').removeClass('d-none')
      $('.extra-stock-field').addClass('d-none')
      $('.extra-pack-field').addClass('d-none')
      $('.create_product_button').removeClass('d-none')
    }
    else {
      $('.detail-form').addClass('d-none')
      $('.stock-form').removeClass('d-none')
    }
  })

  $('.stock_button_previous').on('click', function () {
    $('.stock-form').addClass('d-none')
    $('.detail-form').removeClass('d-none')
    $('.detail-tax-field').addClass('d-none')
  })

  $('.stock_button').on('click', function () {
    $('.stock-form').addClass('d-none')
    $('.extra-form').removeClass('d-none')
    $('.extra-stock-field').removeClass('d-none')
    $('.extra-pack-field').removeClass('d-none')
    $('.create_product_button').removeClass('d-none')
  })

  $('.stock_button_previous').on('click', function () {
    $('.stock-form').addClass('d-none')
    $('.detail-form').removeClass('d-none')
  })

  $('.extra_button_previous').on('click', function () {
    if ((this.parentElement.parentElement.parentElement.parentElement.children[0].children[6].children[1].value) == "Multiple") {
      $('.extra-form').addClass('d-none')
      $('.detail-form').removeClass('d-none')
      $('.detail-tax-field').removeClass('d-none')
      $('.create_product_button').addClass('d-none')
    }
    else {
      $('.extra-form').addClass('d-none')
      $('.detail-form').removeClass('d-none')
      $('.create_product_button').addClass('d-none')
    }
  })
  // Product Create Form JQuery end
})