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
    var title = data[0].title
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
  $('.shipment_modal').on('click', function () {
    var parent = $(this).parent().parent()
    var quantity = $(this).parent().parent().find('.order-quantity')[0].innerHTML
    var length = $(parent).find('.length-value').val() || 0
    var width = $(parent).find('.width-value').val() || 0
    var height = $(parent).find('.height-value').val() || 0
    var weight = $(parent).find('.weight-value').val() || 0
    $('#channel_order_id').val(this.dataset.id)
    $('#mail-service-roles-modal').find('.hidden_length').val(length * quantity)
    $('#mail-service-roles-modal').find('.hidden_weight').val(weight * quantity)
    $('#mail-service-roles-modal').find('.hidden_height').val(height)
    $('#mail-service-roles-modal').find('.hidden_width').val(width)
    $('.mail_service_rule_mail_service_labels_attributes_0_weight').val(weight * quantity)
    $('.mail_service_rule_mail_service_labels_attributes_0_height').val(height)
    $('.mail_service_rule_mail_service_labels_attributes_0_length').val(length * quantity)
    $('.mail_service_rule_mail_service_labels_attributes_0_width').val(width)
    $('#mail-service-roles-modal').modal('show')
  })

  $('.update-rule-modal').on('click', function () {
    var index = this.dataset.index
    $('#update_channel_order_id').val(this.dataset.id)
    $('#mail-service-roles-update-modal-'+index).modal('show')
  })

  $('.bulk-assign-rule').on('click', function () {
    $('#bulk-mail-service-modal').modal('show')
    var object_ids = $('input[name="object_ids[]"]:checked')
    var order_ids = object_ids.map(function (i, e) { return e.value }).toArray();
    var rule_id = $('#rule_id').val()
    $('.assign_bulk_rule_button').on('click', function () {
      var rule_id = $('#rule_id').val()
      $.ajax({
        url: '/order_dispatches/bulk_assign_rule',
        type: 'GET',
        data: { 'orders': order_ids, 'rule': rule_id },
        success: function (response) {
          window.location.reload()
        }
      })
    })
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
    var title = data[0].title
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

  // $('.productSearch').on('focusout', function () {
  //   if ($('.productSearch').value === ''){
  //     $(this).closest('td').find('.productSearchContainer').toggleClass('d-none', 3000);
  //     $(this).closest('td').find('.productSearch').toggleClass('d-none', 3000);
  //   }
  // })
  $('#q_status_eq, #product_mapping, .order-mapping-select, .product-mapping-select').on('change', function () {
    $('.product-mapping-request').trigger('click')
  })

})