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
        log: function () {}
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

    $('.import-btn').on('click', function () {
      $('.import-file').trigger('click')
      $('.import-file').on('change', function () {
        $('.import-submit').trigger('click')
      })
    })

    $('.select-all-checkbox').on("click", function(){
      var cbxs = $('input[name="object_ids[]"]');
      cbxs.prop("checked", !cbxs.prop("checked"));
    });

    $('.bulk-delete-objects').on('click', function () {
      $('.bulk-method-objects').trigger('click')
    })
});

// Preloader JS
$(window).on('turbolinks:load', function () {
    $('.preloader').fadeOut();
});
