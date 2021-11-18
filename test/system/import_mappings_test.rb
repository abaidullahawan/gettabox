require "application_system_test_case"

class ImportMappingsTest < ApplicationSystemTestCase
  setup do
    @import_mapping = import_mappings(:one)
  end

  test "visiting the index" do
    visit import_mappings_url
    assert_selector "h1", text: "Import Mappings"
  end

  test "creating a Import mapping" do
    visit import_mappings_url
    click_on "New Import Mapping"

    fill_in "Mapping data", with: @import_mapping.mapping_data
    fill_in "Table name", with: @import_mapping.table_name
    click_on "Create Import mapping"

    assert_text "Import mapping was successfully created"
    click_on "Back"
  end

  test "updating a Import mapping" do
    visit import_mappings_url
    click_on "Edit", match: :first

    fill_in "Mapping data", with: @import_mapping.mapping_data
    fill_in "Table name", with: @import_mapping.table_name
    click_on "Update Import mapping"

    assert_text "Import mapping was successfully updated"
    click_on "Back"
  end

  test "destroying a Import mapping" do
    visit import_mappings_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Import mapping was successfully destroyed"
  end
end
