import $ from 'jquery'

$(document).on('turbolinks:load', function () {
  $('.allocate-button').on('click', function () {
    $('.bulk-allocation').trigger('click')
  })
})
