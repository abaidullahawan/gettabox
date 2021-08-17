require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get users_card" do
    get pages_users_card_url
    assert_response :success
  end

  test "should get notifications" do
    get pages_notifications_url
    assert_response :success
  end

  test "should get timeline" do
    get pages_timeline_url
    assert_response :success
  end

  test "should get invoice_template" do
    get pages_invoice_template_url
    assert_response :success
  end

  test "should get gallery" do
    get pages_gallery_url
    assert_response :success
  end

  test "should get faq" do
    get pages_faq_url
    assert_response :success
  end

  test "should get pricing" do
    get pages_pricing_url
    assert_response :success
  end

  test "should get profile" do
    get pages_profile_url
    assert_response :success
  end

  test "should get profile_settings" do
    get pages_profile_settings_url
    assert_response :success
  end

  test "should get error-404" do
    get pages_error-404_url
    assert_response :success
  end

end
