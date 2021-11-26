import $ from 'jquery'

$(document).on('turbolinks:load', function () {

  $('.create-single-product').on('click', function () {
    var json = this.dataset.item
    var cd_id = this.dataset.id
    var data = JSON.parse(json)
    var sku = data.item_sku
    var title = data.item_name
    var description = data.product_data.description
    var imageUrl = data.item_image || ''
    var urlSplit = imageUrl.split('/')
    var imageName = urlSplit[urlSplit.length - 1]
    var quantity = data.item_quantity

    $('#single-product-create-modal .modal-body #channel_product_id').val(cd_id)
    $('#single-product-create-modal .modal-body #product_title').val(title)
    $('#single-product-create-modal .modal-body #product_sku').val(sku)
    $('#single-product-create-modal .modal-body #product_description').val(description)
    // $('#single-product-create-modal .modal-body #product_photo').attr("src", imageUrl)
    // $('#single-product-create-modal .modal-body #product_photo').attr("filename", imageName)
    $('#single-product-create-modal .modal-body #product_total_stock').val(quantity)
    if(imageName  !== '' )
    {
      $('#single-product-create-modal .modal-body #photo-label').text(`Photo ${imageName} Attached`)
    }
    $('#single-product-create-modal').modal('show')
  })

  $('.create-single-product-mapping').on('click', function () {
    var json = this.dataset.item
    var cd_id = this.dataset.id
    var data = JSON.parse(json)
    var sku = data[0].sku
    var title = data[0].item_data.title
    // var description = data.product_data.description
    // var imageUrl = data[0].item_data.product_data.PictureDetails.GalleryURL
    // var urlSplit = imageUrl.split('/')
    // var imageName = urlSplit[urlSplit.length - 1]
    // var quantity = data.product_data.Quantity

    $('#single-product-create-modal .modal-body #channel_product_id').val(cd_id)
    $('#single-product-create-modal .modal-body #product_title').val(title)
    $('#single-product-create-modal .modal-body #product_sku').val(sku)
    // $('#single-product-create-modal .modal-body #product_description').val(description)
    // $('#single-product-create-modal .modal-body #product_photo').attr("src", imageUrl)
    // $('#single-product-create-modal .modal-body #product_photo').attr("filename", imageName)
    // $('#single-product-create-modal .modal-body #product_total_stock').val(quantity)
    // if(imageName  !== '' )
    // {
    //   $('#single-product-create-modal .modal-body #photo-label').text(`Photo ${imageName} Attached`)
    // }
    $('#single-product-create-modal').modal('show')
  })

  $('.shippment_modal').on('click', function () {
    $('#mail-service-roles-modal').modal('show')
  })


  $('.create-multi-product').on('click', function () {
    var json = this.dataset.item
    var cd_id = this.dataset.id
    var data = JSON.parse(json)
    var sku = data.item_sku
    var title = data.item_name
    var description = data.product_data.description

    $('#multi-product-create-modal .modal-body #channel_product_id').val(cd_id)
    $('#multi-product-create-modal .modal-body #product_title').val(title)
    $('#multi-product-create-modal .modal-body #product_sku').val(sku)
    $('#multi-product-create-modal .modal-body #product_description').val(description)
    $('#multi-product-create-modal').modal('show')
  })

  $('.create-multi-product-mapping').on('click', function () {
    var json = this.dataset.item
    var cd_id = this.dataset.id
    var data = JSON.parse(json)
    var sku = data[0].sku
    var title = data[0].item_data.title
    // var description = data.product_data.description

    $('#multi-product-create-modal .modal-body #channel_product_id').val(cd_id)
    $('#multi-product-create-modal .modal-body #product_title').val(title)
    $('#multi-product-create-modal .modal-body #product_sku').val(sku)
    // $('#multi-product-create-modal .modal-body #product_description').val(description)
    $('#multi-product-create-modal').modal('show')
  })

  $('.productSearchBtn').on('click', function () {
    $(this).closest('td').find('.productSearchContainer').toggleClass('d-none', 3000);
    $(this).closest('td').find('.productSearch').toggleClass('d-none', 3000);
    $(this).closest('td').find('.productSearch').trigger( "focus" )
  })

  $('.product-mapping-export').on('click', function () {
    $('.product-export-request').trigger( "click" )
    setTimeout(location.reload.bind(location), 5000);
  })

  // $('.productSearch').on('focusout', function () {
  //   if ($('.productSearch').value === ''){
  //     $(this).closest('td').find('.productSearchContainer').toggleClass('d-none', 3000);
  //     $(this).closest('td').find('.productSearch').toggleClass('d-none', 3000);
  //   }
  // })
  $('#q_channel_type_eq, #q_status_eq, #product_mapping, .order-mapping-select, .product-mapping-select').on('change', function () {
    $('.product-mapping-request').trigger('click')
  })

})