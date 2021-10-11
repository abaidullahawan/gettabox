import $ from 'jquery'

$(document).on('turbolinks:load', function () {

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
