$(document).on('turbolinks:load', function () {

  $('.searchclear').on('click', function () {
    $(this).prev('input').val('');
    return false;
  })

  window.dropdown_search = function (url, dropdownClass, listClass, event) {
    var target = event.currentTarget
    var product_title = target.value
    var list_class = '.' + listClass
    var dropdown_class = '.' + dropdownClass

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
            $(dropdown_class).append('<li><a href="#" class="dropdown-item ' + listClass + '" data-option-array-index=' + index + '>' + this + '</a></li>')
          });
        }
      }
    })
    $('.search-list').hide()
    $(target.closest('div')).find('ul').show()

  }
  //-----------------------Category-----------------------
  $('.category-dropdown-list').on('click', '.category-list-item', function () {
    $('#category-title-search').val(this.outerText)
    $(".category-dropdown-list").hide()
    $('#category-title-search').focus()
    return false
  })

  $('.category-dropdown-list').on('focus', '.category-list-item', function () {
    $('#category-title-search').val(this.outerText)
  })
  //-----------------------Products-----------------------
  $('.product-dropdown-list').on('click', '.product-list-item', function () {
    var parent_div = $(this.closest('div'))
    $(parent_div).find('ul').hide()
    $(parent_div).find('input').focus()
    $(parent_div).find('input').val(this.outerText)
    return false
  })

  $('.product-dropdown-list').on('focus', '.product-list-item', function () {
    var parent_div = this.closest('div')
    $(parent_div).find('input').val(this.outerText)
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
