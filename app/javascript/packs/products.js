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
      if (product_type == "Single") {

        $('.basic-info-form').addClass('d-none')
        $('.quantity-form').removeClass('d-none')
      }
      else if (product_type == "Multiple") {
        $('.basic-info-form').addClass('d-none')
        $('.stock-form').removeClass('d-none')
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

  $('.quantity_button_previous').on('click', function () {
    $('.quantity-form').addClass('d-none')
    $('.basic-info-form').removeClass('d-none')
  })

  $('.quantity_button').on('click', function () {
    if ((this.parentElement.parentElement.parentElement.children[2].children[0].children[1].value) == "") {
      alert("Please Enter Total Stock...")
    }
    else {
      $('.quantity-form').addClass('d-none')
      $('.dimensions-form').removeClass('d-none')
    }
  })

  $('.dimensions_button_previous').on('click', function () {
    $('.dimensions-form').addClass('d-none')
    $('.quantity-form').removeClass('d-none')
  })

  $('.dimensions_button').on('click', function () {
    if ((this.parentElement.parentElement.parentElement.children[2].children[3].children[1].value) == "") {
      alert("Please Enter the Weight of item ...")
    }
    else {
      $('.dimensions-form').addClass('d-none')
      $('.stock-form').removeClass('d-none')
    }
  })

  $('.stock_button_previous').on('click', function () {
    if (this.parentElement.parentElement.parentElement.parentElement.children[0].children[6].children[1].value == "Single") {
      $('.stock-form').addClass('d-none')
      $('.dimensions-form').removeClass('d-none')
    }
    else if (this.parentElement.parentElement.parentElement.parentElement.children[0].children[6].children[1].value == "Multiple") {
      $('.stock-form').addClass('d-none')
      $('.basic-info-form').removeClass('d-none')
    }
  })

  $('.stock_button').on('click', function () {
    if ((this.parentElement.parentElement.parentElement.children[2].children[0].children[1].value) == "") {
      alert("Please Enter Minimum Stock...")
    }
    else {
      $('.stock-form').addClass('d-none')
      $('.taxes-form').removeClass('d-none')
    }
  })

  $('.taxes_button_previous').on('click', function () {
    $('.taxes-form').addClass('d-none')
    $('.stock-form').removeClass('d-none')
  })

  $('.taxes_button').on('click', function () {
    $('.taxes-form').addClass('d-none')
    $('.system-user-form').removeClass('d-none')
  })

  $('.system_user_button_previous').on('click', function () {
    $('.system-user-form').addClass('d-none')
    $('.taxes-form').removeClass('d-none')
  })

  $('.system_user_button').on('click', function () {
    if ((this.parentElement.parentElement.parentElement.children[3].children[1].children[0].children[1].value) == "") {
      alert("Please select the Product Supplier ...")
    }
    else {
      $('.system-user-form').addClass('d-none')
      $('.barcode-form').removeClass('d-none')
    }
  })

  $('.barcode_button_previous').on('click', function () {
    $('.barcode-form').addClass('d-none')
    $('.system-user-form').removeClass('d-none')
  })

  $('.barcode_button').on('click', function () {
    $('.barcode-form').addClass('d-none')
    $('.extra-form').removeClass('d-none')
    $('.create_product_button').removeClass('d-none')
  })

  $('.extra_button_previous').on('click', function () {
    $('.extra-form').addClass('d-none')
    $('.barcode-form').removeClass('d-none')
    $('.create_product_button').addClass('d-none')
  })
  // Product Create Form JQuery end
})