import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  purchaseOrderTotal()
  $('.order_item_price').on('blur', function () {
    $('.supplier-submit').trigger('click')
  })

  $('.order_item_price, .order_item_quantity').on('keyup', function () {
    purchaseOrderTotal()
  })

  $('.purchase_delivery').on('click', function () {
    debugger
    $('.purchase_delivery_list').toggleClass('d-none')
  })

})
function purchaseOrderTotal() {
  var length = $('.order_item_price').length
  for (var i = 0; i < length; ++i) {
    var cost_price_id = "purchase_order_purchase_order_details_attributes_" + i + "_cost_price"
    var quantity_id = "purchase_order_purchase_order_details_attributes_" + i + "_quantity"
    var quantity = $("#" + quantity_id).val()
    var cost = $("#" + cost_price_id).val()
    var item_total = (isNaN(parseFloat(quantity) * parseFloat(cost))) ? 0 : parseFloat(quantity) * parseFloat(cost);
    $("#" + quantity_id).closest('tr').find('.order_item_total').val(item_total)

    var sum = 0;
    $('.order_item_total').each(function () {
      var value = (isNaN(this.value)) ? 0 : this.value;
      sum += parseFloat(value);  // Or this.innerHTML, this.innerText
    });
    $('.order_total').val(sum)
  }
}