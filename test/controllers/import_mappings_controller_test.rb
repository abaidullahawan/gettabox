require "test_helper"

class ImportMappingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @import_mapping = import_mappings(:one)
  end

  test "should get index" do
    get import_mappings_url
    assert_response :success
  end

  test "should get new" do
    get new_import_mapping_url
    assert_response :success
  end

  test "should create import_mapping" do
    assert_difference('ImportMapping.count') do
      post import_mappings_url, params: { import_mapping: { mapping_data: @import_mapping.mapping_data, table_name: @import_mapping.table_name } }
    end

    assert_redirected_to import_mapping_url(ImportMapping.last)
  end

  test "should show import_mapping" do
    get import_mapping_url(@import_mapping)
    assert_response :success
  end

  test "should get edit" do
    get edit_import_mapping_url(@import_mapping)
    assert_response :success
  end

  test "should update import_mapping" do
    patch import_mapping_url(@import_mapping), params: { import_mapping: { mapping_data: @import_mapping.mapping_data, table_name: @import_mapping.table_name } }
    assert_redirected_to import_mapping_url(@import_mapping)
  end

  test "should destroy import_mapping" do
    assert_difference('ImportMapping.count', -1) do
      delete import_mapping_url(@import_mapping)
    end

    assert_redirected_to import_mappings_url
  end
end
