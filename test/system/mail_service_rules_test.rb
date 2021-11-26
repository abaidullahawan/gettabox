require "application_system_test_case"

class MailServiceRulesTest < ApplicationSystemTestCase
  setup do
    @mail_service_rule = mail_service_rules(:one)
  end

  test "visiting the index" do
    visit mail_service_rules_url
    assert_selector "h1", text: "Mail Service Rules"
  end

  test "creating a Mail service rule" do
    visit mail_service_rules_url
    click_on "New Mail Service Rule"

    fill_in "Description", with: @mail_service_rule.description
    fill_in "Service name", with: @mail_service_rule.service_name
    click_on "Create Mail service rule"

    assert_text "Mail service rule was successfully created"
    click_on "Back"
  end

  test "updating a Mail service rule" do
    visit mail_service_rules_url
    click_on "Edit", match: :first

    fill_in "Description", with: @mail_service_rule.description
    fill_in "Service name", with: @mail_service_rule.service_name
    click_on "Update Mail service rule"

    assert_text "Mail service rule was successfully updated"
    click_on "Back"
  end

  test "destroying a Mail service rule" do
    visit mail_service_rules_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Mail service rule was successfully destroyed"
  end
end
