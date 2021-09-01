import $ from 'jquery'

$(document).on('turbolinks:load', function () {

  $('.product_type_field').on('change', function () {
    if ((this.value == "Single") || (this.value == "Multiple")) {
      $('.basic_info_button').removeClass('d-none');
    }
    else {
      $('.basic_info_button').addClass('d-none');
    }
  })
  // Product Create Form JQuery start
  $('.basic_info_button').on('click', function () {
    var photo = this.parentElement.children[2].children[1].value
    var title = this.parentElement.children[3].children[1].value
    var sku = this.parentElement.children[4].children[1].value
    var category = this.parentElement.children[5].children[1].value
    var product_type = this.parentElement.children[6].children[1].value
    if ((photo != "") && (title != "") && (sku != "") && (category != "") && (product_type != "")) {
      $('.basic-info-form').addClass('d-none')
      $('.detail-form').removeClass('d-none')
      if (product_type == "Multiple") {
        $('.detail-tax-field').removeClass('d-none')
      }
      else {
        $('.detail-tax-field').addClass('d-none')
      }
    }
    else {
      if (photo == ""){
        alert("Please select a photo")
      }
      else if (title == ""){
        alert("Please Enter a Title")
      }
      else if (sku == ""){
        alert("Please Enter a SKU")
      }
      else if (category == ""){
        alert("Please select a category")
      }
      else if (product_type == ""){
        alert("Please select a product type")
      }
    }
  })

  $('.detail_button_previous').on('click', function () {
    $('.detail-form').addClass('d-none')
    $('.basic-info-form').removeClass('d-none')
  })

  $('.detail_button').on('click', function () {
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