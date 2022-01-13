import $ from 'jquery'
$(document).on('turbolinks:load', function () {
  // Side Menu Hide Show JS
  $(".burger-menu").on('click', function () {
    $(".burger-menu").toggleClass("toggle-menu");
    // $(".navbar-brand").toggleClass("navbar-logo");
    $(".sidemenu-area").toggleClass("sidemenu-toggle");
    $(".sidemenu").toggleClass("hide-nav-title");
    $(".main-content").toggleClass("hide-sidemenu");
  });

  window.currently_working = function (event) {
    if ($("#user_personal_detail_attributes_work_details_attributes_" + event.currentTarget.id.split('_')[7] + "_currently_working").prop('checked') == true) {
      $("#user_personal_detail_attributes_work_details_attributes_" + event.currentTarget.id.split('_')[7] + "_to").closest('.form-group').addClass('d-none');
    }
    else {
      $("#user_personal_detail_attributes_work_details_attributes_" + event.currentTarget.id.split('_')[7] + "_to").closest('.form-group').removeClass('d-none');
    }
  }

  // Burger menu click show toggle x class
  $(".burger-menu").on('click', function () {
    $(".burger-menu").toggleClass("x");
  });

  // Feather Icon Js
  feather.replace();

  // Tooltip JS
  $('[data-toggle="tooltip"]').tooltip();

  // Gallery Viewer JS
  var console = window.console || {
    log: function () { }
  };
  var $images = $('.gallery-content');
  var $toggles = $('.gallery-toggles');
  var $buttons = $('.gallery-buttons');
  var options = {
    // inline: true,
    url: 'data-original',
    ready: function (e) {
      console.log(e.type);
    },
    show: function (e) {
      console.log(e.type);
    },
    shown: function (e) {
      console.log(e.type);
    },
    hide: function (e) {
      console.log(e.type);
    },
    hidden: function (e) {
      console.log(e.type);
    },
    view: function (e) {
      console.log(e.type);
    },
    viewed: function (e) {
      console.log(e.type);
    }
  };

  function toggleButtons(mode) {
    if (/modal|inline|none/.test(mode)) {
      $buttons
        .find('button[data-enable]')
        .prop('disabled', true)
        .filter('[data-enable*="' + mode + '"]')
        .prop('disabled', false);
    }
  }
  $images.on({
    ready: function (e) {
      console.log(e.type);
    },
    show: function (e) {
      console.log(e.type);
    },
    shown: function (e) {
      console.log(e.type);
    },
    hide: function (e) {
      console.log(e.type);
    },
    hidden: function (e) {
      console.log(e.type);
    },
    view: function (e) {
      console.log(e.type);
    },
    viewed: function (e) {
      console.log(e.type);
    }
  }).viewer(options);
  toggleButtons(options.inline ? 'inline' : 'modal');
  $toggles.on('change', 'input', function () {
    var $input = $(this);
    var name = $input.attr('name');
    options[name] = name === 'inline' ? $input.data('value') : $input.prop('checked');
    $images.viewer('destroy').viewer(options);
    toggleButtons(options.inline ? 'inline' : 'modal');
  });
  $buttons.on('click', 'button', function () {
    var data = $(this).data();
    var args = data.arguments || [];
    if (data.method) {
      if (data.target) {
        $images.viewer(data.method, $(data.target).val());
      } else {
        $images.viewer(data.method, args[0], args[1]);
      }
      switch (data.method) {
        case 'scaleX':
        case 'scaleY':
          args[0] = -args[0];
          break;
        case 'destroy':
          toggleButtons('none');
          break;
      }
    }
  });

  // FAQ Accordion Js
  $('.accordion').find('.accordion-title').on('click', function () {
    // Adds Active Class
    $(this).toggleClass('active');
    // Expand or Collapse This Panel
    $(this).next().slideToggle('fast');
    // Hide The Other Panels
    // $('.accordion-content').not($(this).next()).slideUp('fast');
    // Removes Active Class From Other Titles
    // $('.accordion-title').not($(this)).removeClass('active');
  });
  // Page Per User
  $('#change_per_page').on('change', function () {
    $('#per_page_submit').trigger('click')
  })
  $('#orders_per_page').on('change', function () {
    $('.product-mapping-request').trigger('click')
  })

  $('#customSwitchAll').on('click', function () {
    var switches = $('.orders-switch');
    switches.prop("checked", this.checked);
    var selected = []
    var unselected = []
    switches.each(function () {
      if (this.checked) {
        selected.push(this.id)
      }
      else {
        unselected.push(this.id)
      }
    })
    $.ajax({
      url: '/order_dispatches/bulk_update_selected',
      type: 'GET',
      data: { 'selected': selected, 'unselected': unselected },
      success: function (response) {
        if (response.result) {
          $('.jquery-selected-alert').html('All objects updated successfully')
          $('.jquery-selected-alert').addClass('bg-success').removeClass('d-none').removeClass('bg-danger')
          $(".jquery-selected-alert").fadeTo(2000, 500).slideUp(500, function () {
            $(".jquery-selected-alert").slideUp(500);
          });
        }
      }
    })
  })

  $('.customSwitch1').on('click', function () {
    var value = this.checked
    var order_id = this.id

    $.ajax({
      url: '/order_dispatches/update_selected',
      type: "GET",
      data: { 'selected': value, 'order_id': order_id },
      success: function (response) {
        if (response.result) {
          $('.jquery-selected-alert').html('Object updated successfully')
          $('.jquery-selected-alert').addClass('bg-success').removeClass('d-none').removeClass('bg-danger')
          $(".jquery-selected-alert").fadeTo(2000, 500).slideUp(500, function () {
            $(".jquery-selected-alert").slideUp(500);
          });
        }
        else {
          $('.jquery-selected-alert').html('Object cannot be updated! ' + response.errors[0])
          $('.jquery-selected-alert').addClass('bg-danger').removeClass('d-none')
          $('.jquery-selected-alert').alert('show')
          $(".jquery-selected-alert").fadeTo(2000, 500).slideUp(500, function () {
            $(".jquery-selected-alert").slideUp(500);
          });
        }
      }
    })
  })

  $('.import-btn').on('click', function () {
    $('.import-file').trigger('click')
    $('.import-file').on('change', function () {
      $('.import-submit').trigger('click')
    })
  })

  $('.select-all-checkbox').on("click", function () {
    var cbxs = $('input[name="object_ids[]"]');
    cbxs.prop("checked", !cbxs.prop("checked"));
  });

  $('.bulk-delete-objects').on('click', function () {
    $('.bulk-method-delete-objects').trigger('click')
  })

  $('.courier-value').on('change', function () {
  })

  $('.create_service_rule_button').on('click', function () {
    $('.bulk-method-order-dispatch').trigger('click')
  })

  $('.order-dispatch-button').on('click', function () {
    $('.bulk-courier-order-dispatch').trigger('click')
  })

  $('#export_mapping_table_name').on('change', function () {
    var table = $("#export_mapping_table_name").val()
    $.ajax({
      url: '/table_name',
      type: 'GET',
      data: { 'table_name': table },
      success: function (response) {
        $('.check-boxes').html('')
        $.each(response, function (index, val) {
          $('.check-boxes').append('<div class= "col-3">' + '<input type="checkbox" name="' + val + '" >' + '<label for="' + val + '"> ' + val + ' </label>' + '</br>' + '</div>')
        });
      }
    })
  })

  $('#extra_field_name_field_type').on('change', function () {
    var field_name = $("#extra_field_name_field_type").val()
    if (field_name === 'Select') {
      $('.add-association-button').removeClass('d-none')
    } else {
      $('.add-association-button').addClass('d-none')
    }
  })

  $("tr[data-link]").click(function () {
    window.location = $(this).data("link")
  })

  $('.new-service-rule-modal').on('click', function () {
    var courier = this.dataset.courier
    var service = this.dataset.service
    $.ajax({
      url: '/mail_service_rules/search_courier_services',
      data: { 'courier_id': courier },
      type: "GET",
      dataType: "json",
      success: function (response) {
        $("#mail_service_rule_service_id").html('')
        if (response == null) {
          $("#mail_service_rule_service_id").append('<option>-- Please select courier first --</option>')
        }
        else {
          $("#mail_service_rule_service_id").append('<option>-- Select One --</option>')
          for (var i = 0; i < response.length; i++) {
            $("#mail_service_rule_service_id").append('<option value="' + response[i]["id"] + '">' + response[i]["name"] + '</option>');
          }
          $('#mail_service_rule_service_id').val(service)
        }
      }
    })
    $('#mail_service_rule_courier_id').val(courier)
  })

  $('#order_batch_print_packing_list').on('click', function () {
    var option = this.checked
    $('#order_batch_print_packing_list_option').prop('disabled', !option)
    if (option) {
      $($('#order_batch_print_packing_list_option').closest('div')).removeClass('d-none')
    }
    else {
      $($('#order_batch_print_packing_list_option').closest('div')).addClass('d-none')
    }
  })

  $('.one-click-dispatch').on('click', function () {
    var object_ids = $('input[name="object_ids[]"]:checked')
    var order_ids = object_ids.map(function (i, e) { return e.value }).toArray();
    var count = 0
    object_ids.map(function (i, e) { return count = count + parseInt(e.dataset.item) })
    var export_ids = object_ids.map(function (i, e) { return e.dataset.export }).toArray();
    var same_export = export_ids.every((val, i, arr) => val === arr[0])
    var rule = object_ids.map(function (i, e) { return e.dataset.courier }).toArray();
    var same_rule = rule.every((val, i, arr) => val === arr[0]) && rule[0] == 'Manual Dispatch'
    if (same_rule) {
      $('.order_batch_print_courier_labels').addClass('d-none')
      $('.manual-dispatch-csv').removeClass('d-none')
    }
    else {
      $('.order_batch_print_courier_labels').removeClass('d-none')
      $('.manual-dispatch-csv').addClass('d-none')
    }
    if (!same_export) {
      $('.jquery-selected-alert').html('Please select orders with same rule and export')
      $('.jquery-selected-alert').addClass('bg-danger').removeClass('d-none').removeClass('bg-success')
      $(".jquery-selected-alert").fadeTo(4000, 500).slideUp(500, function () {
        $(".jquery-selected-alert").slideUp(500);
      });
    }
    else if (object_ids.length > 0) {
      $('.total_orders').html(object_ids.length)
      $('.total_products').html(count)
      $('input[name="order_ids"]').val(order_ids)
      $('.OrderBatchModal').modal('show')
    }
    else {
      $('.jquery-selected-alert').html('Please select orders first!')
      $('.jquery-selected-alert').addClass('bg-danger').removeClass('d-none').removeClass('bg-success')
      $(".jquery-selected-alert").fadeTo(4000, 500).slideUp(500, function () {
        $(".jquery-selected-alert").slideUp(500);
      });
    }
  })

  // $('.OrderBatchModal').on('hidden.bs.modal', function () {
  //   if ($('.OrderBatchSubmit').is(":disabled")) {
  //     window.location.reload()
  //   }
  // })

  $('.OrderBatchSubmit').on('click', function () {
    var object_ids = $('input[name="object_ids[]"]:checked')
    var rule = object_ids.map(function (i, e) { return e.dataset.courier }).toArray();
    var same_rule = rule.every((val, i, arr) => val === arr[0]) && rule[0] == 'Manual Dispatch'
    if (same_rule){
      $('.upload-trackings').modal('show')
    }
  })

  $('#q_sales_channel_eq').on('change', function () {
    $('.customer_ransack_submit').trigger('click')
  })
});

// Preloader JS
$(window).on('turbolinks:load', function () {
  $('.preloader').fadeOut();
});
