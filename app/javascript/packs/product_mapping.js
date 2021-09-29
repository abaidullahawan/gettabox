import $ from 'jquery'

$(document).on('turbolinks:load', function () {

  $('.create-single-product').on('click', function () {
    debugger;
    var json = this.dataset.item
    var cd_id = this.dataset.id
    var data = JSON.parse(json)
    var sku = data.product_data.sku
    var title = data.product_data.product.title
    var description = data.product_data.product.description
    // var imageUrl = data.product_data.product.imageUrls[0]
    // var urlSplit = imageUrl.split('/')
    // var imageName = urlSplit[urlSplit.length - 1]
    var quantity = data.product_data.availability.shipToLocationAvailability.quantity

    $('#single-product-create-modal .modal-body #channel_product_id').val(cd_id)
    $('#single-product-create-modal .modal-body #product_title').val(title)
    $('#single-product-create-modal .modal-body #product_sku').val(sku)
    $('#single-product-create-modal .modal-body #product_description').val(description)
    // $('#single-product-create-modal .modal-body #product_photo').attr("src", imageUrl)
    // $('#single-product-create-modal .modal-body #product_photo').attr("filename", imageName)
    $('#single-product-create-modal .modal-body #product_total_stock').val(quantity)
    $('#single-product-create-modal').modal('show')
  })

  $('.create-multi-product').on('click', function () {
    debugger;
    var json = this.dataset.item
    var cd_id = this.dataset.id
    var data = JSON.parse(json)
    var sku = data.product_data.sku
    var title = data.product_data.product.title
    var description = data.product_data.product.description

    $('#multi-product-create-modal .modal-body #channel_product_id').val(cd_id)
    $('#multi-product-create-modal .modal-body #product_title').val(title)
    $('#multi-product-create-modal .modal-body #product_sku').val(sku)
    $('#multi-product-create-modal .modal-body #product_description').val(description)
    $('#multi-product-create-modal').modal('show')
  })
})