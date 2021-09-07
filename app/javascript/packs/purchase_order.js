import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  $('.order_item_price').on('blur', function () {
    $('.supplier-submit').trigger('click')
  })
  $('.order_item_price, .order_item_quantity').on('keyup', function () {
    var name = this.id
    var quantity_field = this.id.replace('quantity', 'cost_price')
    var cost_price_field = this.id.replace('cost_price', 'quantity')
    var quantity = $("#" + quantity_field).val()
    var cost = $("#" + cost_price_field).val()
    var item_total = quantity * cost

    $(this).closest('tr').find('.order_item_total').val(item_total)
    debugger;
    var sum = 0;
    $('.order_item_total').each(function () {
      sum += parseFloat($(this).val());  // Or this.innerHTML, this.innerText
    });
    $('.order_total').val(sum)

  })
})
