require "test_helper"

class MailServiceRulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mail_service_rule = mail_service_rules(:one)
  end

  test "should get index" do
    get mail_service_rules_url
    assert_response :success
  end

  test "should get new" do
    get new_mail_service_rule_url
    assert_response :success
  end

  test "should create mail_service_rule" do
    assert_difference('MailServiceRule.count') do
      post mail_service_rules_url, params: { mail_service_rule: { description: @mail_service_rule.description, service_name: @mail_service_rule.service_name } }
    end

    assert_redirected_to mail_service_rule_url(MailServiceRule.last)
  end

  test "should show mail_service_rule" do
    get mail_service_rule_url(@mail_service_rule)
    assert_response :success
  end

  test "should get edit" do
    get edit_mail_service_rule_url(@mail_service_rule)
    assert_response :success
  end

  test "should update mail_service_rule" do
    patch mail_service_rule_url(@mail_service_rule), params: { mail_service_rule: { description: @mail_service_rule.description, service_name: @mail_service_rule.service_name } }
    assert_redirected_to mail_service_rule_url(@mail_service_rule)
  end

  test "should destroy mail_service_rule" do
    assert_difference('MailServiceRule.count', -1) do
      delete mail_service_rule_url(@mail_service_rule)
    end

    assert_redirected_to mail_service_rules_url
  end
end
