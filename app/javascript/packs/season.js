import $ from 'jquery'

$(document).on('turbolinks:load', function () {

  $('.season-dropdown-list').on('click', '.season-list-item', function () {
    $('#season-name-search').val(this.outerText)
    $('.season-dropdown-list').hide()
    $('#season-name-search').focus()
    return false
  })

  $('.season-dropdown-list').on('focus', '.season-list-item', function () {
    $('#season-name-search').val(this.outerText)
  })

})
