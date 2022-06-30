import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  purchaseOrderTotal()

  $('.order_item_price, .order_item_quantity').on('keyup', function () {
    purchaseOrderTotal()
  })

  $('.quantity_type').on('change', function () {
    purchaseOrderTotal()
  })

  $('.purchase_delivery').on('click', function () {
    $(this).find('.purchase_delivery_list').toggleClass('d-none')
  })

  if ($('.payment_method_value').val() == "paid") {
    $('.payment_method').attr('checked', 'checked');
  }
  else {
    $('.payment_method').removeAttr('checked');
  }

  $('.payment_method').on('click', function () {
    if (this.checked == true) {
      $('.payment_method_value').val("paid")
    }
    else {
      $('.payment_method_value').val("unpaid")
    }
    $('.edit_purchase_order').submit();
  })

  $('.productSearchOrderField').on('keyup', function (e) {
    if (e.key === 'Enter' || e.keyCode === 13) {
      $('.displayCheck').removeClass('displayCheck')
      $('.rowDisplay').removeClass('rowDisplay')
      var product_sku_list = $('.productSkuSearch')
      for (var i = 0; i < product_sku_list.length; i++) {
        if (!product_sku_list[i].textContent.toLocaleLowerCase().includes($(this).val().toLocaleLowerCase())) {
          if (!product_sku_list[i].closest('tr').classList.contains('rowDisplay')) {
            product_sku_list[i].closest('tr').classList.add('d-none')
          }
          if (!product_sku_list[i].parentElement.closest('.accordion').classList.contains('displayCheck')) {
            product_sku_list[i].parentElement.closest('.accordion').classList.add('d-none')
          }
        }
        else {
          product_sku_list[i].closest('tr').classList.remove('d-none')
          product_sku_list[i].closest('tr').classList.add('rowDisplay')
          product_sku_list[i].parentElement.closest('.accordion').classList.remove('d-none')
          product_sku_list[i].parentElement.closest('.accordion').classList.add('displayCheck')
        }
      }
    }
  })

  $(".clickable-row").click(function () {
    window.location = $(this).data("href");
  });

})
function purchaseOrderTotal() {
  var length = $('.order_item_price').length
  var item_price_ids = $('.order_item_price').map(function () {
    return $(this).attr('id');
  }).get();
  var item_quantity_ids = $('.order_item_quantity').map(function () {
    return $(this).attr('id');
  }).get();
  var quantity_type_ids = $('.quantity_type').map(function () {
    return $(this).attr('id');
  }).get();
  for (var i = 0; i < length; ++i) {
    var cost_price_id = item_price_ids[i]
    var quantity_id = item_quantity_ids[i]
    var quantity_type = quantity_type_ids[i]
    var quantity = $("#" + quantity_id).val()
    var selected = $("option:selected", $("#" + quantity_type)).text()
    var q = 1
    $("#" + quantity_id).closest('tr').find('#quantity_type_hidden').find('option').each(function () {
      if (this.text == selected) {
        q = $(this).val()
      }
    });
    var cost = $("#" + cost_price_id).val()
    quantity = quantity * q
    var item_total = (isNaN(parseFloat(quantity) * parseFloat(cost))) ? 0 : parseFloat(quantity) * parseFloat(cost);
    $("#" + quantity_id).closest('tr').find('.order_item_total').val(item_total.toFixed(2))

    var sum = 0;
    $('.order_item_total').each(function () {
      var value = (this.value) == '' ? 0 : this.value;
      sum += parseFloat(value).toFixed(2) * 1;  // Or this.innerHTML, this.innerText
    });
    $('.order_total').val(sum)
  }
}