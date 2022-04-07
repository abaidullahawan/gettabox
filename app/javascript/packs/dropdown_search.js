$(document).on('turbolinks:load', function () {

  $('.searchclear').on('click', function () {
    $(this).prev('input').val('');
    return false;
  })
  

  window.dropdown_search_product = function (url, dropdownClass, listClass, event) {
    var target = event.currentTarget
    var product_title = target.value
    var list_class = '.' + listClass
    var dropdown_class = '.' + dropdownClass
    var startTag = '<b>'
    var endTag = '</b>'

    $.ajax({
      url: url,
      type: "POST",
      data: { 'search_value': product_title },
      success: function (response) {
        var index = 0;
        $(list_class).remove()
        $(dropdown_class).children().remove()
        if (response.length == 0) {
          index += 1;
          $(dropdown_class).append('<li><a href="#" class="dropdown-item ' + listClass + '" data-option-array-index=' + index + '>No result found</a></li>')
        }
        else {
          $.each(response, function () {
            index += 1;
            $(dropdown_class).append('<li class="d-flex"><a data-id=' + this[0] + ' class="cursor-pointer dropdown-item ' + listClass + '" data-option-array-index=' + index + '>' + startTag + this.slice(1).slice(0,1) + endTag  + ', ' + this.slice(1).slice(1) + '</a><button class="ml-auto mr-4 btn btn-primary map-modal-button">Map</button></li><hr class="my-1">')
          });
        }
      }
    })
    $('.search-list').hide()
    $(target.closest('div')).find('ul').show()

  }

  window.dropdown_search = function (url, dropdownClass, listClass, event) {
    var target = event.currentTarget
    var product_title = target.value
    var list_class = '.' + listClass
    var dropdown_class = '.' + dropdownClass
    var startTag = '<b>'
    var endTag = '</b>'
    var product_selected_arr = []

    for(var i = 0; i < $('.multipack-products-field').length; i++){
      product_selected_arr.push($('.multipack-products-field')[i].value)
    }

    $.ajax({
      url: url,
      type: "POST",
      data: { 'search_value': product_title, 'product_selected': product_selected_arr },
      success: function (response) {
        var index = 0;
        $(list_class).remove()
        $(dropdown_class).children().remove()
        if (response.length == 0) {
          index += 1;
          $(dropdown_class).append('<li><a href="#" class="dropdown-item ' + listClass + '" data-option-array-index=' + index + '>No result found</a></li>')
        }
        else {
          $.each(response, function () {
            index += 1;
            $(dropdown_class).append('<li><a href="#" data-id=' + this[0] + ' class="dropdown-item ' + listClass + '" data-option-array-index=' + index + '>' + startTag + this.slice(1).slice(0,1) + endTag  + ', ' + this.slice(1).slice(1) + '</a></li>')
          });
        }
      }
    })
    $('.search-list').hide()
    $(target.closest('div')).find('ul').show()

  }

  window.dropdown_search_batch = function (url, dropdownClass, listClass, event) {
    var target = event.currentTarget
    var product_title = target.value
    var list_class = '.' + listClass
    var dropdown_class = '.' + dropdownClass
    var startTag = '<b>'
    var endTag = '</b>'
    var product_selected_arr = []

    for(var i = 0; i < $('.multipack-products-field').length; i++){
      product_selected_arr.push($('.multipack-products-field')[i].value)
    }

    $.ajax({
      url: url,
      type: "POST",
      data: { 'search_value': product_title, 'product_selected': product_selected_arr },
      success: function (response) {
        var index = 0;
        $(list_class).remove()
        $(dropdown_class).children().remove()
        if (response.length == 0) {
          index += 1;
          $(dropdown_class).append('<li><a class="d-flex dropdown-item add-batch-name cursor-pointer">'+product_title+'<svg class="ml-auto" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="20" height="20" viewBox="0 0 256 256" xml:space="preserve"><desc>Created with Fabric.js 1.7.22</desc><defs></defs><g transform="translate(128 128) scale(0.72 0.72)" style=""><g style="stroke: none; stroke-width: 0; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: none; fill-rule: nonzero; opacity: 1;" transform="translate(-175.05 -175.05000000000004) scale(3.89 3.89)" ><circle cx="45" cy="45" r="45" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(32,196,203); fill-rule: nonzero; opacity: 1;" transform="  matrix(1 0 0 1 0 0) "/><path d="M 41.901 78.5 c -1.657 0 -3 -1.343 -3 -3 V 20.698 c 0 -1.657 1.343 -3 3 -3 s 3 1.343 3 3 V 75.5 C 44.901 77.157 43.558 78.5 41.901 78.5 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(27,167,173); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" /><path d="M 69.302 51.1 H 14.5 c -1.657 0 -3 -1.343 -3 -3 s 1.343 -3 3 -3 h 54.802 c 1.657 0 3 1.343 3 3 S 70.959 51.1 69.302 51.1 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(27,167,173); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" /><path d="M 45.099 75.302 c -1.657 0 -3 -1.343 -3 -3 V 17.5 c 0 -1.657 1.343 -3 3 -3 s 3 1.343 3 3 v 54.802 C 48.1 73.959 46.756 75.302 45.099 75.302 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(255,255,255); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" /><path d="M 72.5 47.9 H 17.698 c -1.657 0 -3 -1.343 -3 -3 s 1.343 -3 3 -3 H 72.5 c 1.657 0 3 1.343 3 3 S 74.157 47.9 72.5 47.9 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(255,255,255); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" /></g></g></svg></a></li>')
        }
        else {
          $.each(response, function () {
            index += 1;
            $(dropdown_class).append('<li><a href="#" data-id=' + this[0] + ' class="dropdown-item ' + listClass + '" data-option-array-index=' + index + '>' + startTag + this.slice(1).slice(0,1) + endTag + this.slice(1).slice(1) + '</a></li>')
          });
        }
      }
    })
    $('.search-list').hide()
    $(target.closest('div')).find('ul').show()

  }

  $(document).on('click', '.add-batch-name', function(){
    var batch_name = $('#batch-name-search').val()
    $.ajax({
      url: '/order_batches/save_batch_name',
      type: 'GET',
      data: { batch_name: batch_name },
      success: function (response) {
        if (response.message == null){
        }
        else{
          $('.jquery-selected-alert').html(response.message)
          $('.jquery-selected-alert').addClass('bg-danger').removeClass('d-none').removeClass('bg-success')
          $(".jquery-selected-alert").fadeTo(2000, 500).slideUp(500, function () {
            $(".jquery-selected-alert").slideUp(500);
          });
        }
      }
    })
  });

  //-----------------------Category-----------------------
  $('.category-dropdown-list').on('click', '.category-list-item', function () {
    $(".category-dropdown-list").hide()
    $('#category-title-search').focus()
    var parent_div = $(this.closest('div'))
    $($(parent_div).find('input')[1]).val(this.dataset.id)
    $($(parent_div).find('input')[0]).val(this.outerText)
    return false
  })

  $('.category-dropdown-list').on('focus', '.category-list-item', function () {
    var parent_div = $(this.closest('div'))
    $($(parent_div).find('input')[1]).val(this.dataset.id)
    $($(parent_div).find('input')[0]).val(this.outerText)
  })
  //-----------------------Products-----------------------
  $('.product-dropdown-list').on('click', '.product-list-item', function () {
    var parent_div = $(this.closest('div'))
    $(parent_div).find('ul').hide()
    $(parent_div).find('input')[0].focus()
    $($(parent_div).find('input')[1]).val(this.dataset.id)
    $($(parent_div).find('input')[0]).val(this.outerText)
    return false
  })

  $('.product-dropdown-list').on('click', '.map-modal-button', function(){
    var parent_div = $(this.closest('div'))
    $(parent_div).find('ul').hide()
    $(parent_div).find('input')[0].focus()
    $($(parent_div).find('input')[1]).val(this.parentElement.children[0].dataset.id)
    $($(parent_div).find('input')[0]).val(this.parentElement.children[0].outerText)
    parent_div.parent().parent().find('.map-submit-button').trigger('click')
  })

  $('.product-dropdown-list').on('focus', '.product-list-item', function () {
    var parent_div = this.closest('div')
    $($(parent_div).find('input')[1]).val(this.dataset.id)
    $($(parent_div).find('input')[0]).val(this.outerText)
  })

  $('.product-sku-dropdown-list').on('click', '.product-sku-list-item', function () {
    $('.product-sku-dropdown-list').hide()
    $('#product-sku-search').focus()
    $('#product-sku-search').val(this.outerText)
    return false
  })

  $('.product-sku-dropdown-list').on('focus', '.product-sku-list-item', function () {
    $('#product-sku-search').val(this.outerText)
  })

  $('.card, .card-body, .card-header, .main-content, .main-content-header, .row').on('click', function () {
    $('.search-list').hide();
  })

  $('.category-dropdown-list').on('click', '.category-list-item', function () {
    $('#category-title-search').val(this.outerText);
    $('#category-title-search-multiple').val(this.outerText);
    $('.category-dropdown-list').hide();
    return false;
  })

  $('.category-dropdown-list').on('focus', '.category-list-item', function () {
    $('#category-title-search').val(this.outerText);
    $('#category-title-search-multiple').val(this.outerText);
  })

  //----------------------Seasons-----------------------
  $('.season-dropdown-list').on('click', '.season-list-item', function () {
    $('#season-name-search').val(this.outerText)
    $('.season-dropdown-list').hide()
    $('#season-name-search').focus()
    return false
  })

  $('.season-dropdown-list').on('focus', '.season-list-item', function () {
    $('#season-name-search').val(this.outerText)
  })

  //-------------------OrderBatches------------------
  $('.batch-dropdown-list').on('click', '.batch-list-item', function () {
    $('#batch-name-search').val(this.outerText)
    $('.batch-dropdown-list').hide()
    $('#batch-name-search').focus()
    return false
  })

  $('.batch-dropdown-list').on('focus', '.batch-list-item', function () {
    $('#batch-name-search').val(this.outerText)
  })

  //-------------------SystemUsers------------------
  $('.supplier-name-dropdown-list').on('click', '.supplier-name-list-item', function () {
    $('#supplier-name-search').val(this.outerText)
    $('.supplier-name-dropdown-list').hide();
    $('#supplier-name-search').focus();
    return false
  })

  $('.supplier-name-dropdown-list').on('focus', '.supplier-name-list-item', function () {
    $('#supplier-name-search').val(this.outerText)
  })
})
