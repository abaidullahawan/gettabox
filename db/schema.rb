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

ActiveRecord::Schema.define(version: 2021_09_02_123323) do

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
    t.index ["deleted_at"], name: "index_categories_on_deleted_at"
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

  create_table "multipack_products", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "child_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["child_id"], name: "index_multipack_products_on_child_id"
    t.index ["product_id"], name: "index_multipack_products_on_product_id"
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

  create_table "product_suppliers", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "system_user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "product_cost"
    t.string "product_sku"
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
    t.decimal "hst"
    t.decimal "pst"
    t.decimal "qst"
    t.decimal "minimum"
    t.decimal "maximum"
    t.decimal "optimal"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.integer "product_type"
    t.bigint "season_id"
    t.text "description"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["season_id"], name: "index_products_on_season_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_seasons_on_deleted_at"
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
    t.index ["deleted_at"], name: "index_system_users_on_deleted_at"
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
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
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
  add_foreign_key "product_suppliers", "products"
  add_foreign_key "product_suppliers", "system_users"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "seasons"
  add_foreign_key "users", "users", column: "created_by"
end
