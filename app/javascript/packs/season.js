import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  $('#season-name-search').on('keyup', function () {
    var season_name = this.value
    $(".season-dropdown-list").show()
    $.ajax({
      url: "/seasons/season_by_name",
      type: "POST",
      data: { 'season_name': season_name },
      success: function(response) {
        $(".season-list-item").remove()
        if(response.length == 0) {
          $(".season-dropdown-list").append('<li><a href="#" class="dropdown-item season-list-item">No result found</a></li>')
        }
        else {
          $(".season-dropdown-list").append('<li><a href="#" class="dropdown-item season-list-item">Select Supplier</a></li>')
          $.each(response,function() {
            $(".season-dropdown-list").append('<li><a href="#" class="dropdown-item season-list-item">'+ this.name +'</a></li>')
          });
        }
      }
    })
  })

  $('.season-dropdown-list').on('click', '.season-list-item', function () {
    $('#season-name-search').val(this.outerText)
    $('#season_search').submit();
  })

  $('#season-name-search').on('blur', function () {
    $(".season-dropdown-list").hide()
  })
})
