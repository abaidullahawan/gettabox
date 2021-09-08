import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  purchaseDeliveryTotal()

  $('.order_item_price, .order_item_quantity').on('keyup', function () {
    purchaseDeliveryTotal()
  })

})
function purchaseDeliveryTotal() {
  var length = $('.order_item_price').length
  for (var i = 0; i < length; ++i) {
    var cost_price_id = "purchase_delivery_purchase_delivery_details_attributes_" + i + "_cost_price"
    var quantity_id = "purchase_delivery_purchase_delivery_details_attributes_" + i + "_quantity"
    var quantity = $("#" + quantity_id).val()
    var cost = $("#" + cost_price_id).val()
    var item_total = (isNaN(parseFloat(quantity) * parseFloat(cost))) ? 0 : parseFloat(quantity) * parseFloat(cost);
    $("#" + quantity_id).closest('tr').find('.order_item_total').val(item_total)

    var sum = 0;
    $('.order_item_total').each(function () {
      var value = (isNaN(this.value)) ? 0 : this.value;
      sum += parseFloat(value);  // Or this.innerHTML, this.innerText
    });
    $('#purchase_delivery_total_bill').val(sum)
  }
}