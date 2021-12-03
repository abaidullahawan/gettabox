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
})
