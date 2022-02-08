import $ from 'jquery'

$(document).on('turbolinks:load', function () {
    $('.refund-field').on('keyup', function(){
        var fund_value = parseFloat($(this).val()).toFixed(2);
        var total_order_value = parseFloat($('.total-order-value').text()).toFixed(2);
        var total_value = total_order_value - fund_value;
        $('.refund-value').text(fund_value)
        $('.total-value').text(total_value.toFixed(2))
    })
})
