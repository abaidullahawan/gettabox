# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_05_19_092308) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "company"
    t.string "address"
    t.string "city"
    t.string "region"
    t.string "postcode"
    t.string "country"
    t.string "addressable_type"
    t.bigint "addressable_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "address_title"
    t.string "name"
    t.index ["addressable_type", "addressable_id"], name: "index_addresses_on_addressable"
  end

  create_table "assign_rules", force: :cascade do |t|
    t.bigint "mail_service_rule_id"
    t.boolean "save_later"
    t.integer "status"
    t.text "product_ids"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "criteria"
    t.index ["mail_service_rule_id"], name: "index_assign_rules_on_mail_service_rule_id"
  end

  create_table "attribute_settings", force: :cascade do |t|
    t.string "model"
    t.bigint "user_id"
    t.integer "setting_type"
    t.json "table_attributes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_attribute_settings_on_user_id"
  end

  create_table "barcodes", force: :cascade do |t|
    t.string "title"
    t.bigint "product_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["product_id"], name: "index_barcodes_on_product_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "description"
    t.datetime "deleted_at"
    t.boolean "selected"
    t.index ["deleted_at"], name: "index_categories_on_deleted_at"
  end

  create_table "channel_forecastings", force: :cascade do |t|
    t.integer "filter_name"
    t.string "filter_by"
    t.integer "action"
    t.integer "type_number"
    t.integer "units"
    t.string "name"
    t.string "comparison_number"
    t.bigint "system_user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["system_user_id"], name: "index_channel_forecastings_on_system_user_id"
  end

  create_table "channel_order_items", force: :cascade do |t|
    t.string "sku"
    t.json "item_data"
    t.bigint "channel_order_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "line_item_id"
    t.integer "ordered"
    t.bigint "channel_product_id"
    t.bigint "assign_rule_id"
    t.bigint "product_id"
    t.boolean "allocated"
    t.string "title"
    t.index ["assign_rule_id"], name: "index_channel_order_items_on_assign_rule_id"
    t.index ["channel_order_id"], name: "index_channel_order_items_on_channel_order_id"
    t.index ["channel_product_id"], name: "index_channel_order_items_on_channel_product_id"
    t.index ["product_id"], name: "index_channel_order_items_on_product_id"
  end

  create_table "channel_orders", force: :cascade do |t|
    t.integer "channel_type"
    t.jsonb "order_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "order_id"
    t.string "order_status"
    t.string "payment_status"
    t.float "total_amount"
    t.string "buyer_name"
    t.string "buyer_username"
    t.integer "channel_order_id"
    t.string "fulfillment_instruction"
    t.bigint "assign_rule_id"
    t.boolean "selected"
    t.bigint "system_user_id"
    t.boolean "ready_to_print"
    t.bigint "order_batch_id"
    t.string "stage"
    t.string "order_type"
    t.jsonb "product_scan"
    t.string "change_log"
    t.string "concession_amount"
    t.string "refund_amount"
    t.string "replacement_id"
    t.boolean "update_channel", default: false
    t.string "postage"
    t.float "total_weight"
    t.index ["assign_rule_id"], name: "index_channel_orders_on_assign_rule_id"
    t.index ["order_batch_id"], name: "index_channel_orders_on_order_batch_id"
    t.index ["system_user_id"], name: "index_channel_orders_on_system_user_id"
  end

  create_table "channel_products", force: :cascade do |t|
    t.integer "channel_type"
    t.jsonb "product_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "listing_id"
    t.string "item_sku"
    t.integer "status", default: 0
    t.string "item_name"
    t.string "item_image"
    t.string "error_message"
    t.decimal "item_quantity"
    t.string "product_range_id"
    t.string "range_sku"
    t.bigint "assign_rule_id"
    t.boolean "selected"
    t.string "item_price"
    t.bigint "channel_forecasting_id"
    t.boolean "customize"
    t.string "buffer_quantity"
    t.string "listing_type"
    t.index ["assign_rule_id"], name: "index_channel_products_on_assign_rule_id"
    t.index ["channel_forecasting_id"], name: "index_channel_products_on_channel_forecasting_id"
  end

  create_table "channel_response_data", force: :cascade do |t|
    t.integer "channel"
    t.jsonb "response"
    t.string "api_call"
    t.string "api_url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "status"
  end

  create_table "contact_details", force: :cascade do |t|
    t.string "phone_number"
    t.string "email"
    t.string "street_address"
    t.string "city"
    t.string "province"
    t.string "country"
    t.integer "zip"
    t.bigint "personal_detail_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["personal_detail_id"], name: "index_contact_details_on_personal_detail_id"
  end

  create_table "couriers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.boolean "selected"
    t.index ["deleted_at"], name: "index_couriers_on_deleted_at"
  end

  create_table "credentials", force: :cascade do |t|
    t.string "redirect_uri"
    t.string "grant_type"
    t.text "authorization"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "template_type"
    t.string "template_name"
    t.string "subject"
    t.string "body"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "export_mappings", force: :cascade do |t|
    t.string "table_name"
    t.string "sub_type"
    t.json "export_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "mapping_data"
  end

  create_table "extra_field_names", force: :cascade do |t|
    t.string "field_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "table_name"
    t.string "field_type"
  end

  create_table "extra_field_options", force: :cascade do |t|
    t.bigint "extra_field_name_id"
    t.string "option_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["extra_field_name_id"], name: "index_extra_field_options_on_extra_field_name_id"
  end

  create_table "extra_field_values", force: :cascade do |t|
    t.json "field_value"
    t.string "fieldvalueable_type"
    t.bigint "fieldvalueable_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["fieldvalueable_type", "fieldvalueable_id"], name: "index_extra_field_values_on_fieldvalueable"
  end

  create_table "general_settings", force: :cascade do |t|
    t.string "name"
    t.string "display_name"
    t.string "phone"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "import_mappings", force: :cascade do |t|
    t.string "table_name"
    t.json "mapping_data", default: {}
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "sub_type"
    t.json "header_data"
    t.json "table_data"
    t.string "mapping_type"
    t.json "data_to_print"
    t.json "mapping_rule"
  end

  create_table "job_statuses", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.string "job_id"
    t.json "arguments"
    t.datetime "perform_in"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "mail_service_labels", force: :cascade do |t|
    t.float "weight"
    t.float "height"
    t.float "width"
    t.float "length"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "assign_rule_id"
    t.index ["assign_rule_id"], name: "index_mail_service_labels_on_assign_rule_id"
  end

  create_table "mail_service_rules", force: :cascade do |t|
    t.string "service_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "channel_order_id"
    t.text "rule_name"
    t.float "public_cost"
    t.float "initial_weight"
    t.float "additonal_cost_per_kg"
    t.float "vat_percentage"
    t.integer "label_type"
    t.integer "csv_file"
    t.integer "courier_account"
    t.integer "rule_naming_type"
    t.integer "manual_dispatch_label_template"
    t.integer "priority_delivery_days"
    t.boolean "is_priority"
    t.integer "estimated_delivery_days"
    t.bigint "courier_id"
    t.bigint "service_id"
    t.integer "print_queue_type"
    t.integer "additional_label"
    t.integer "pickup_address"
    t.integer "bonus_score"
    t.float "base_weight"
    t.float "base_weight_max"
    t.datetime "deleted_at"
    t.boolean "selected"
    t.boolean "tracking_import"
    t.bigint "export_mapping_id"
    t.index ["channel_order_id"], name: "index_mail_service_rules_on_channel_order_id"
    t.index ["courier_id"], name: "index_mail_service_rules_on_courier_id"
    t.index ["deleted_at"], name: "index_mail_service_rules_on_deleted_at"
    t.index ["export_mapping_id"], name: "index_mail_service_rules_on_export_mapping_id"
    t.index ["service_id"], name: "index_mail_service_rules_on_service_id"
  end

  create_table "multifile_mappings", force: :cascade do |t|
    t.string "file1"
    t.string "file2"
    t.boolean "download"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "sub_type"
    t.string "error"
  end

  create_table "multipack_products", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "child_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "quantity"
    t.index ["child_id"], name: "index_multipack_products_on_child_id"
    t.index ["product_id"], name: "index_multipack_products_on_product_id"
  end

  create_table "notes", force: :cascade do |t|
    t.string "message"
    t.bigint "user_id"
    t.string "reference_type"
    t.bigint "reference_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["reference_type", "reference_id"], name: "index_notes_on_reference"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "order_batches", force: :cascade do |t|
    t.string "pick_preset"
    t.boolean "print_packing_list"
    t.boolean "orders"
    t.boolean "products"
    t.boolean "mark_as_picked"
    t.boolean "print_courier_labels"
    t.date "print_date"
    t.boolean "print_invoice"
    t.boolean "update_channels"
    t.boolean "mark_order_as_dispatched"
    t.string "batch_name"
    t.boolean "shipping_rule_max_weight"
    t.boolean "overwrite_order_notes"
    t.string "options"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "print_packing_list_option"
    t.bigint "user_id"
    t.datetime "deleted_at"
    t.string "status"
    t.integer "preset_type"
    t.boolean "mark_as_batch_name"
    t.index ["deleted_at"], name: "index_order_batches_on_deleted_at"
    t.index ["user_id"], name: "index_order_batches_on_user_id"
  end

  create_table "order_replacements", force: :cascade do |t|
    t.bigint "channel_order_id"
    t.bigint "order_replacement_id"
    t.string "order_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["channel_order_id"], name: "index_order_replacements_on_channel_order_id"
    t.index ["order_replacement_id"], name: "index_order_replacements_on_order_replacement_id"
  end

  create_table "personal_details", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "full_name"
    t.date "dob"
    t.integer "gender"
    t.string "bio_type"
    t.bigint "bio_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["bio_type", "bio_id"], name: "index_personal_details_on_bio"
  end

  create_table "product_forecastings", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "channel_forecasting_id"
    t.index ["channel_forecasting_id"], name: "index_product_forecastings_on_channel_forecasting_id"
    t.index ["product_id"], name: "index_product_forecastings_on_product_id"
  end

  create_table "product_locations", force: :cascade do |t|
    t.string "location"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "product_mappings", force: :cascade do |t|
    t.bigint "channel_product_id"
    t.bigint "product_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["channel_product_id"], name: "index_product_mappings_on_channel_product_id"
    t.index ["product_id"], name: "index_product_mappings_on_product_id"
  end

  create_table "product_suppliers", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "system_user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "product_cost"
    t.string "product_sku"
    t.decimal "product_vat"
    t.index ["product_id"], name: "index_product_suppliers_on_product_id"
    t.index ["system_user_id"], name: "index_product_suppliers_on_system_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "sku"
    t.string "title"
    t.decimal "total_stock"
    t.decimal "fake_stock"
    t.decimal "pending_orders"
    t.decimal "allocated_orders"
    t.decimal "available_stock"
    t.bigint "category_id"
    t.decimal "length"
    t.decimal "width"
    t.decimal "height"
    t.decimal "weight"
    t.string "pack_quantity"
    t.decimal "cost_price"
    t.decimal "gst"
    t.decimal "vat"
    t.decimal "minimum"
    t.decimal "maximum"
    t.decimal "optimal"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.integer "product_type"
    t.bigint "season_id"
    t.text "description"
    t.string "barcode"
    t.boolean "selected"
    t.string "change_log"
    t.integer "manual_edit_stock"
    t.integer "unshipped"
    t.integer "inventory_balance"
    t.integer "unallocated"
    t.bigint "product_location_id"
    t.decimal "allocated"
    t.integer "unshipped_orders"
    t.string "courier_type"
    t.bigint "channel_forecasting_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["channel_forecasting_id"], name: "index_products_on_channel_forecasting_id"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["product_location_id"], name: "index_products_on_product_location_id"
    t.index ["season_id"], name: "index_products_on_season_id"
  end

  create_table "purchase_deliveries", force: :cascade do |t|
    t.bigint "purchase_order_id", null: false
    t.decimal "total_bill"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_purchase_deliveries_on_deleted_at"
    t.index ["purchase_order_id"], name: "index_purchase_deliveries_on_purchase_order_id"
  end

  create_table "purchase_delivery_details", force: :cascade do |t|
    t.bigint "purchase_delivery_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.decimal "cost_price"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "missing"
    t.integer "demaged"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_purchase_delivery_details_on_deleted_at"
    t.index ["product_id"], name: "index_purchase_delivery_details_on_product_id"
    t.index ["purchase_delivery_id"], name: "index_purchase_delivery_details_on_purchase_delivery_id"
  end

  create_table "purchase_order_details", force: :cascade do |t|
    t.bigint "purchase_order_id"
    t.bigint "product_id"
    t.decimal "cost_price"
    t.integer "quantity"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "vat"
    t.integer "missing"
    t.integer "demaged"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_purchase_order_details_on_deleted_at"
    t.index ["product_id"], name: "index_purchase_order_details_on_product_id"
    t.index ["purchase_order_id"], name: "index_purchase_order_details_on_purchase_order_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.bigint "supplier_id"
    t.decimal "total_bill"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.integer "order_status"
    t.integer "payment_method"
    t.index ["deleted_at"], name: "index_purchase_orders_on_deleted_at"
    t.index ["supplier_id"], name: "index_purchase_orders_on_supplier_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.string "channel"
    t.string "refresh_token"
    t.datetime "refresh_token_expiry"
    t.string "access_token"
    t.datetime "access_token_expiry"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "rules", force: :cascade do |t|
    t.string "rule_field"
    t.string "rule_operator"
    t.text "rule_value"
    t.boolean "is_optional"
    t.bigint "mail_service_rule_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["mail_service_rule_id"], name: "index_rules_on_mail_service_rule_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.boolean "selected"
    t.index ["deleted_at"], name: "index_seasons_on_deleted_at"
  end

  create_table "sellings", force: :cascade do |t|
    t.string "name"
    t.integer "quantity"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "courier_id"
    t.datetime "deleted_at"
    t.boolean "selected"
    t.index ["courier_id"], name: "index_services_on_courier_id"
    t.index ["deleted_at"], name: "index_services_on_deleted_at"
  end

  create_table "study_details", force: :cascade do |t|
    t.string "school"
    t.string "degree"
    t.integer "format"
    t.text "description"
    t.date "from"
    t.date "to"
    t.bigint "personal_detail_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["personal_detail_id"], name: "index_study_details_on_personal_detail_id"
  end

  create_table "system_users", force: :cascade do |t|
    t.integer "user_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.integer "delivery_method"
    t.integer "payment_method"
    t.integer "days_for_payment"
    t.integer "days_for_order_to_completion"
    t.integer "days_for_completion_to_delivery"
    t.string "currency_symbol"
    t.decimal "exchange_rate"
    t.datetime "deleted_at"
    t.string "email"
    t.string "phone_number"
    t.boolean "selected"
    t.string "sales_channel"
    t.datetime "flagging_date"
    t.index ["deleted_at"], name: "index_system_users_on_deleted_at"
  end

  create_table "trackings", force: :cascade do |t|
    t.string "tracking_no"
    t.string "order_id"
    t.bigint "channel_order_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "carrier"
    t.string "service"
    t.string "shipping_service"
    t.index ["channel_order_id"], name: "index_trackings_on_channel_order_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "role"
    t.integer "created_by"
    t.datetime "deleted_at"
    t.boolean "selected"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type"
    t.string "{:null=>false}"
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "work_details", force: :cascade do |t|
    t.string "company_name"
    t.string "position"
    t.string "city"
    t.text "description"
    t.boolean "currently_working"
    t.date "from"
    t.date "to"
    t.bigint "personal_detail_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["personal_detail_id"], name: "index_work_details_on_personal_detail_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attribute_settings", "users"
  add_foreign_key "channel_orders", "assign_rules"
  add_foreign_key "mail_service_rules", "export_mappings"
  add_foreign_key "product_suppliers", "products"
  add_foreign_key "product_suppliers", "system_users"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "product_locations"
  add_foreign_key "products", "seasons"
  add_foreign_key "purchase_deliveries", "purchase_orders"
  add_foreign_key "purchase_delivery_details", "products"
  add_foreign_key "purchase_delivery_details", "purchase_deliveries"
  add_foreign_key "users", "users", column: "created_by"
end
