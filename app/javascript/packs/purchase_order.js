import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  purchaseOrderTotal()

  $('.order_item_price, .order_item_quantity').on('keyup', function () {
    purchaseOrderTotal()
  })

  $('.purchase_delivery').on('click', function () {
    $(this).find('.purchase_delivery_list').toggleClass('d-none')
  })

  if($('.payment_method_value').val() == "paid") {
      $('.payment_method').attr('checked', 'checked');
    }
    else {
      $('.payment_method').removeAttr('checked');
    }

  $('.payment_method').on('click', function () {
    if(this.checked == true){
      $('.payment_method_value').val("paid")
    }
    else {
      $('.payment_method_value').val("unpaid")
    }
    $('.edit_purchase_order').submit();
  })

  $('.productSearchOrderField').on('keyup', function(e){
    $('.accordion-container').removeClass('displayCheck')
    if (e.key === 'Enter' || e.keyCode === 13) {
      var product_sku_list = $('.productSkuSearch')
      for(var i =0; i < product_sku_list.length; i++){
        if (!product_sku_list[i].textContent.includes($(this).val())){
          product_sku_list[i].parentElement.parentElement.classList.add('d-none')
          if (!product_sku_list[i].parentElement.closest('.accordion').classList.contains('displayCheck'))
          {
            product_sku_list[i].parentElement.closest('.accordion').classList.add('d-none')
          }
        }
        else{
          product_sku_list[i].parentElement.parentElement.classList.remove('d-none')
          product_sku_list[i].parentElement.closest('.accordion').classList.remove('d-none')
          product_sku_list[i].parentElement.closest('.accordion').classList.add('displayCheck')
        }
      }
    }
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
      sum += parseFloat(value).toFixed(2) * 1 ;  // Or this.innerHTML, this.innerText
    });
    $('.order_total').val(sum)
  }
}