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
    var switches = $('input[name="orders-switch"]');
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
        if (response.result){
          alert(response.message);
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
        if (response.result){
          // alert('Order updated as selected true!');
        }
        else if(response.result == 'error'){
          // alert('Order cannot be updated!');
        }
        else{
          // alert('Order updated as selected false!');
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
    $('.bulk-method-order-disaptch').trigger('click')
  })

});

// Preloader JS
$(window).on('turbolinks:load', function () {
  $('.preloader').fadeOut();
});
