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
            $(dropdown_class).append('<li><a href="#" data-id=' + this[0] + ' class="dropdown-item ' + listClass + '" data-option-array-index=' + index + '>' + startTag + this.slice(1).slice(0,1) + endTag  + ', ' + this.slice(1).slice(1) + '</a></li>')
          });
        }
      }
    })
    $('.search-list').hide()
    $(target.closest('div')).find('ul').show()

  }
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
