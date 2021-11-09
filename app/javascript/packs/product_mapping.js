import $ from 'jquery'

$(document).on('turbolinks:load', function () {

  $('.create-single-product').on('click', function () {
    var json = this.dataset.item
    var cd_id = this.dataset.id
    var data = JSON.parse(json)
    var sku = data.item_sku
    var title = data.product_data.Title
    var description = data.product_data.description
    var imageUrl = data.product_data.PictureDetails.GalleryURL
    // var urlSplit = imageUrl.split('/')
    // var imageName = urlSplit[urlSplit.length - 1]
    var quantity = data.product_data.Quantity

    $('#single-product-create-modal .modal-body #channel_product_id').val(cd_id)
    $('#single-product-create-modal .modal-body #product_title').val(title)
    $('#single-product-create-modal .modal-body #product_sku').val(sku)
    $('#single-product-create-modal .modal-body #product_description').val(description)
    // $('#single-product-create-modal .modal-body #product_photo').attr("src", imageUrl)
    // $('#single-product-create-modal .modal-body #product_photo').attr("filename", imageName)
    $('#single-product-create-modal .modal-body #product_total_stock').val(quantity)
    if(imageUrl  != '' )
    {
      $('#single-product-create-modal .modal-body #photo-label').innerText = 'Photo Attached';
    }
    $('#single-product-create-modal').modal('show')
  })

  $('.create-multi-product').on('click', function () {
    var json = this.dataset.item
    var cd_id = this.dataset.id
    var data = JSON.parse(json)
    var sku = data.item_sku
    var title = data.product_data.Title
    var description = data.product_data.description

    $('#multi-product-create-modal .modal-body #channel_product_id').val(cd_id)
    $('#multi-product-create-modal .modal-body #product_title').val(title)
    $('#multi-product-create-modal .modal-body #product_sku').val(sku)
    $('#multi-product-create-modal .modal-body #product_description').val(description)
    $('#multi-product-create-modal').modal('show')
  })

  $('.productSearchBtn').on('click', function () {
    $(this).closest('td').find('.productSearchContainer').toggleClass('d-none', 3000);
    $(this).closest('td').find('.productSearch').toggleClass('d-none', 3000);
    $(this).closest('td').find('.productSearch').trigger( "focus" )
  })

  $('.productSearch').on('focusout', function () {
    $(this).closest('td').find('.productSearchContainer').toggleClass('d-none', 3000);
    $(this).closest('td').find('.productSearch').toggleClass('d-none', 3000);
  })

  $('#q_status_eq, #product_mapping').on('change', function () {
    $('.product-mapping-request').trigger('click')
  })

})