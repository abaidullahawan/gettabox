require "application_system_test_case"

class CouriersTest < ApplicationSystemTestCase
  setup do
    @courier = couriers(:one)
  end

  test "visiting the index" do
    visit couriers_url
    assert_selector "h1", text: "Couriers"
  end

  test "creating a Courier" do
    visit couriers_url
    click_on "New Courier"

    fill_in "Name", with: @courier.name
    click_on "Create Courier"

    assert_text "Courier was successfully created"
    click_on "Back"
  end

  test "updating a Courier" do
    visit couriers_url
    click_on "Edit", match: :first

    fill_in "Name", with: @courier.name
    click_on "Update Courier"

    assert_text "Courier was successfully updated"
    click_on "Back"
  end

  test "destroying a Courier" do
    visit couriers_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Courier was successfully destroyed"
  end
end
