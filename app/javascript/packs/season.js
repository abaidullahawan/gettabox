import $ from 'jquery'

$(document).on('turbolinks:load', function () {

  $('#mail_service_rule_courier_id').on('change', function(){
    var a = this.value
    $.ajax({
      url: '/mail_service_rules/search_courier_services',
      data: {'courier_id': a},
      type: "GET",
      dataType: "json",
      success: function (response) {
        $("#mail_service_rule_service_id").html('')
        if (response == null){
          $("#mail_service_rule_service_id").append('<option>-- Please select courier first --</option>')
        }
        else {
          $("#mail_service_rule_service_id").append('<option>-- Select One --</option>')
          for (var i = 0; i < response.length; i++) {
            $("#mail_service_rule_service_id").append('<option value="' + response[i]["id"] + '">' + response[i]["name"] + '</option>');
          }
        }
      }
    })
  })

  $('.rule_field').on('change', function () {
    var field = this.value
    $.ajax({
      url: '/mail_service_rules/search_courier_services',
      context: this,
      data: { 'rule_field': field },
      type: "GET",
      dataType: "json",
      success: function (response) {
        var row = this.closest('.row')
        var rule_operator = $(row).find('.rule_operator')
        var rule_value = $(row).find('.rule_value')
        rule_operator.html('')
        if (response == true) {
          rule_operator.closest('div').addClass('d-none')
          rule_value.closest('div').addClass('col-5')
        }
        else {
          rule_value.closest('div').removeClass('col-5')
          rule_operator.closest('div').removeClass('d-none')
          $.each(response, function (key, value) {
            var o = new Option(value, key);
            $(o).html(value);
            $(rule_operator).append(o)
          });
        }
      }
    })
  })
})
