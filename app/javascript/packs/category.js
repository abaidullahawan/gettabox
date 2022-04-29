import $ from 'jquery'

$(document).on('turbolinks:load', function () {
    $('.refund-field').on('keyup', function(){
        var fund_value = parseFloat($(this).val()).toFixed(2);
        var total_order_value = parseFloat($('.total-order-value').text()).toFixed(2);
        var total_value = total_order_value - fund_value;
        $('.refund-value').text(fund_value)
        $('.total-value').text(total_value.toFixed(2))
    })

    // $('.filter-name-field').on('change', function(){
    //     var selected_value = $(this).val()
    //     if(selected_value == "product_sku")
    //     {
    //         $('.filter-container').removeClass('col-6')
    //         $('.filter-by-field-container').removeClass('col-6')
    //         $('.filter-by-field').removeClass('d-none')
    //         $('.filter-supplier').addClass('d-none')
    //         $('.filter-empty').addClass('d-none')
    //         $('.custom-number-field').removeClass('d-none')
    //         $('.channel-type').addClass('d-none')
    //         $('.filter-by-field').removeAttr('disabled')
    //         $('.channel-type').attr('disabled', true)
    //     }
    //     else if(selected_value == "supplier")
    //     {
    //         $('.filter-container').addClass('col-6')
    //         $('.filter-by-field-container').addClass('col-6')
    //         $('.filter-by-field').addClass('d-none')
    //         $('.filter-supplier').removeClass('d-none')
    //         $('.filter-empty').addClass('d-none')
    //         $('.channel-type').addClass('d-none')
    //         $('.custom-number-field').addClass('d-none')
    //         $('.filter-by-field').attr('disabled', true)
    //         $('.channel-type').attr('disabled', true)
    //     }
    //     else if(selected_value == "channel")
    //     {
    //         $('.filter-container').addClass('col-6')
    //         $('.filter-by-field-container').addClass('col-6')
    //         $('.filter-by-field').addClass('d-none')
    //         $('.filter-supplier').addClass('d-none')
    //         $('.filter-empty').addClass('d-none')
    //         $('.custom-number-field').addClass('d-none')
    //         $('.filter-by-field').attr('disabled', true)
    //         $('.channel-type').removeClass('d-none')
    //         $('.channel-type').removeAttr('disabled')
    //     }
    //     else{
    //         $('.filter-container').addClass('col-6')
    //         $('.filter-by-field-container').addClass('col-6')
    //         $('.filter-by-field').addClass('d-none')
    //         $('.filter-supplier').addClass('d-none')
    //         $('.filter-empty').removeClass('d-none')
    //         $('.channel-type').addClass('d-none')
    //         $('.custom-number-field').addClass('d-none')
    //         $('.filter-by-field').attr('disabled', true)
    //         $('.channel-type').attr('disabled', true)
    //     }
    // })

    $('#_inventory_reports_date_range').on('change', function () {
        var selectedValue = $(this).val();
        $.ajax({
            url: '/inventory_reports/date_picker_from_to',
            type: 'GET',
            data: { 'selectedValue': selectedValue },
            dataType: 'json',
            success: function (response) {
                $('#date_from').val(response.start_date);
                $('#date_to').val(response.end_date);
            }
          })
    });
    $('#date_range').on('change', function () {
        var selectedValue = $(this).val();
        $.ajax({
            url: '/transaction_reports/date_picker_from_to',
            type: 'GET',
            data: { 'selectedValue': selectedValue },
            dataType: 'json',
            success: function (response) {
                $('#date_from').val(response.start_date);
                $('#date_to').val(response.end_date);
            }
          })
    });
    $('#date_range').on('change', function () {
        var selectedValue = $(this).val();
        $.ajax({
            url: '/dispatch_reports/date_picker_from_to',
            type: 'GET',
            data: { 'selectedValue': selectedValue },
            dataType: 'json',
            success: function (response) {
                $('#date_from').val(response.start_date);
                $('#date_to').val(response.end_date);
            }
          })
    });
})
