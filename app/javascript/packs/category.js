import $ from 'jquery'

$(document).on('turbolinks:load', function () {
    $('.refund-field').on('keyup', function(){
        var fund_value = parseFloat($(this).val()).toFixed(2);
        var total_order_value = parseFloat($('.total-order-value').text()).toFixed(2);
        var total_value = total_order_value - fund_value;
        $('.refund-value').text(fund_value)
        $('.total-value').text(total_value.toFixed(2))
    })

    $('.filter-name-field').on('change', function(){
        var selected_value = $(this).val()
        if(selected_value == "product_sku" || selected_value == "channel")
        {
            $('.filter-container').removeClass('col-6')
            $('.filter-by-field-container').removeClass('col-6')
            $('.filter-by-field').removeClass('d-none')
            $('.filter-supplier').addClass('d-none')
            $('.filter-empty').addClass('d-none')
            $('.custom-number-field').removeClass('d-none')
        }
        else if(selected_value == "supplier")
        {
            $('.filter-container').addClass('col-6')
            $('.filter-by-field-container').addClass('col-6')
            $('.filter-by-field').addClass('d-none')
            $('.filter-supplier').removeClass('d-none')
            $('.filter-empty').addClass('d-none')
            $('.custom-number-field').addClass('d-none')
        }
        else{
            $('.filter-container').addClass('col-6')
            $('.filter-by-field-container').addClass('col-6')
            $('.filter-by-field').addClass('d-none')
            $('.filter-supplier').addClass('d-none')
            $('.filter-empty').removeClass('d-none')
            $('.custom-number-field').addClass('d-none')
        }
    })
})
