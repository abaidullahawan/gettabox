import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  $('#category-title-search').on('keyup', function () {
    var category_title = this.value
    $.ajax({
      url: "/categories/category_by_title",
      type: "POST",
      data: { 'category_title': category_title },
      success: function(response) {
        $(".category-list-item").remove()
        if(response.length == 0) {
          $(".category-dropdown-list").append('<li><a href="#" class="dropdown-item category-list-item">No result found</a></li>')
        }
        else {
          $.each(response,function() {
            $(".category-dropdown-list").append('<li><a href="#" class="dropdown-item category-list-item">'+ this.title +'</a></li>')
          });
        }
      }
    })
  })

  $('.category-dropdown-list').on('click', '.category-list-item', function () {
    $('#category-title-search').val(this.outerText)
    $(".category-dropdown-list").hide()
    $('#category-title-search').focus()
    return false
  })

  $('.category-dropdown-list').on('focus', '.category-list-item', function () {
    $('#category-title-search').val(this.outerText)
  })

})
