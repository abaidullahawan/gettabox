# frozen_string_literal: true

# Getting new orders and creating
class OrderDispatchesController < ApplicationController
  include NewProduct
  include AutoAssignRule
  before_action :authenticate_user!
  # before_action :refresh_token, :refresh_token_amazon, only: %i[index all_order_data]
  before_action :check_status, only: %i[index fetch_response_orders]
  before_action :ransack_params, :unmatched_product_orders, :completed_orders,
                :no_sku, :not_started_orders, :unpaid_orders, :unmatched_sku, :ready_to_print_orders,
                :customer_info, :load_counts, only: %i[index]
  before_action :new_product, :product_load_resources, :first_or_create_category, only: %i[index]

  def index
    ChannelOrder.update_all(selected: false)
    @order_exports = ExportMapping.where(table_name: 'ChannelOrder')
    all_order_data if params[:orders_api].present?
    @assign_rule = AssignRule.new
    @assign_rule.mail_service_labels.build
    @order_batch = OrderBatch.new
    respond_to do |format|
      format.html
      format.csv
      format.pdf do
        render pdf: 'file.pdf', viewport_size: '1280x1024', template: 'order_dispatches/index.pdf.erb'
      end
    end
  end

  def show
    @order = ChannelOrder.find(params[:id])
    @new_order = ChannelOrder.new
    @new_order.channel_order_items.build
    @notes = @order.notes
    @note = @order.notes.build
  end

  def create
    @order = ChannelOrder.create(order_dispatches_params)
    if @order.save
      @order.channel_order_items.each do |item|
        if item.product.present?
          item.update(sku: item.product.sku)
          item.product.update(unshipped: item.product.unshipped.to_i - item.ordered&.to_i,
                              change_log: "Manual Order, #{@order.id}, #{@order.order_id}, Manual Order, #{params[:channel_order][:buyer_name]}")
        end
        current_order = ChannelOrder.find_by(id: params[:channel_order]['id'])
        replacement_id = "R#{current_order.order_replacements.count + 1}-#{current_order.id}"
        @order.update(replacement_id: replacement_id, change_log: "Order Paid, #{@order.id}, #{@order.order_id}, #{current_user&.personal_detail&.full_name}", stage: 'ready_to_dispatch')
        OrderReplacement.create(channel_order_id: current_order.id, order_replacement_id: @order.id, order_id: replacement_id)
        current_order.update(change_log: "Replacement, #{replacement_id}, #{current_order.order_id}, #{current_user&.personal_detail&.full_name}")
      end
      flash[:notice] = 'Order Created!'
    else
      flash[:alert] = @order.errors.full_messages
    end
    redirect_to request.referrer
  end

  def all_order_data
    if params[:amazon]
      # job_data = AmazonOrderJob.set(wait: 5.minutes).perform_later
      JobStatus.create(name: 'AmazonOrderJob', status: 'inqueue', perform_in: 300)
      flash[:notice] = 'Amazon order job created!'
    else
      # job_data = CreateChannelOrderResponseJob.perform_later
      JobStatus.create(name: 'CreateChannelOrderResponseJob', status: 'inqueue', perform_in: 300)
      flash[:notice] = 'CALL sent to eBay API'
    end
    redirect_to order_dispatches_path(order_filter: 'unprocessed')
  end

  def update
    order = ChannelOrder.find_by(id: params[:channel_order]['id'])
    if order.update(order_dispatches_params)
      order.update(change_log: "Refund, #{params[:channel_order]['refund_amount'].to_f+params[:channel_order]['concession_amount'].to_f}, #{order.order_id}, #{current_user&.personal_detail&.full_name}")
      flash[:notice] = 'Order refunded successfuly'
    else
      flash[:alert] = @order.errors.full_messages
    end
    redirect_to request.referrer
  end

  def export_csv(orders)
    if params[:export_mapping].present?
      @export_mapping = ExportMapping.find(params[:export_mapping])
      attributes = @export_mapping.export_data.excluding('order_data', 'product_scan')
      @csv = CSV.generate(headers: true) do |csv|
        headers = attributes.including('Delivery Name', 'Postcode')
        csv << headers
        orders.each do |order|
          data = attributes.map { |attr| order.send(attr) }
          data.map! { |x| x.nil? ? ' ' : x }
          delivery_name = order.system_user&.addresses&.where(address_title: 'delivery')&.first&.name
          postcode = order.system_user&.addresses&.where(address_title: 'delivery')&.first&.postcode
          data.push(delivery_name, postcode)
          csv << data
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "orders-#{Date.today}.csv" }
      end
    else
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data csv_export(orders), filename: "orders-#{Date.today}.csv" }
      end
    end
  end

  def courier_csv_export(orders)
    @all_rules = []
    orders = orders.joins(:assign_rule).includes(:assign_rule)
    orders.each do |order|
      @all_rules.push(order.assign_rule.mail_service_rule.export_mapping_id)
    end
    @rules = @all_rules.uniq.compact
    if @rules.count == 1
      rule = @rules.first
      @export_mapping = ExportMapping.find_by(id: rule)
      rule_name = @export_mapping.sub_type
      to_be_ignored = %w[id user_type selected created_at updated_at]
      channel_order_data = {}
      channel_order_item_data = {}
      address_data = {}
      system_user_data = {}
      mail_service_label_data = {}
      @export_mapping.mapping_data.compact_blank.each do |key, attribute|
        channel_order_data[key] = attribute if ChannelOrder.column_names.include? attribute
        if ChannelOrderItem.column_names.excluding(to_be_ignored).include? attribute
          channel_order_item_data[key] =
            attribute
        end
        address_data[key] = attribute if Address.column_names.excluding(to_be_ignored).include? attribute
        system_user_data[key] = attribute if SystemUser.column_names.excluding(to_be_ignored).include? attribute
        if MailServiceLabel.column_names.excluding(to_be_ignored).include? attribute
          mail_service_label_data[key] =
            attribute
        end
      end
      attributes = channel_order_data.keys + channel_order_item_data.keys + system_user_data.keys + address_data.keys + mail_service_label_data.keys
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        orders.each do |order|
          next unless order.assign_rule.mail_service_rule.export_mapping_id == rule

          order.update(stage: 'ready_to_print')
          order_csv = channel_order_data.values.map { |attr| order.send(attr) }
          item_csv = channel_order_item_data.values.map { |attr| order.channel_order_items.first.send(attr) }
          address_csv = address_data.values.map do |attr|
            order.system_user&.addresses&.find_by(address_title: 'delivery')&.send(attr)
          end
          system_user_csv = system_user_data.values.map { |attr| order.system_user&.send(attr) }
          label_csv = mail_service_label_data.values.map do |attr|
            order.assign_rule.mail_service_labels.first.send(attr)
          end
          csv << order_csv + item_csv + system_user_csv + address_csv + label_csv
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "#{rule_name}.csv" }
      end
      flash[:alert] = 'Courier CSV Export Done!'
    else
      flash[:alert] = 'Please select order with same template'
      redirect_to order_dispatches_path(order_filter: 'ready')
    end
  end

  def fetch_response_orders
    if @status.zero?
      flash[:notice] = 'Please CALL eBay Orders.'
    else
      # job_data = CreateChannelOrderJob.perform_later
      JobStatus.create(name: 'CreateChannelOrderJob', status: 'inqueue', perform_in: 300)
      flash[:notice] = 'eBay Orders are saving . . .'
    end
    redirect_to order_dispatches_path(order_filter: 'unprocessed')
  end

  def bulk_method
    return unless params[:object_ids].excluding('0').present?

    return bulk_allocation if params['commit'].eql? 'allocation'

    if params[:commit] == 'courier_csv'
      @orders = ChannelOrder.where(id: params[:object_ids].excluding('0'), selected: true)
      courier_csv_export(@orders)
    else
      @assign_rule = AssignRule.create(mail_service_rule_id: params[:rule_id]) # changed save later true unneccassarily
      @service_label = MailServiceLabel.create(height: params[:height], weight: params[:weight],
                                               length: params[:length], width: params[:width], assign_rule_id: @assign_rule.id)
      order_ids = params[:object_ids].excluding('0')
      order_ids.each do |order|
        channel_order = ChannelOrder.find(order)
        channel_order&.update(assign_rule_id: @assign_rule.id)
      end
      redirect_to request.referrer
      flash[:notice] = 'Mail Service Rule Assigned!'
    end
  end

  def assign_rule
    service_rule = MailServiceRule.find(params[:rule_name])
    if params[:next_time] == '1'
      ChannelOrder.find(params[:channel_order_id])&.channel_order_items&.each do |order_item|
        order_item.update(mail_service_rule_id: service_rule.id)
        ChannelProduct.where(item_sku: order_item.sku).update_all(mail_service_rule_id: service_rule.id)
        ChannelOrderItem.where(sku: order_item.sku).update_all(mail_service_rule_id: service_rule.id)
      end
    else
      ChannelOrder.find(params[:channel_order_id])&.channel_order_items&.each do |order_item|
        order_item.update(mail_service_rule_id: params[:rule_name])
      end
    end
    redirect_to request.referrer
    flash[:notice] = 'Mail Service Rule Assigned!'
  end

  def bulk_assign_rule
    orders = ChannelOrder.find(params[:orders])
    @assign_rule = AssignRule.create(mail_service_rule_id: params[:rule])
    orders.each do |order|
      order&.update(assign_rule_id: @assign_rule.id)
      order&.channel_order_items&.each do |item|
        quantity = item&.ordered
        length = item&.channel_product&.product_mapping&.product&.length.to_f * quantity
        weight = item&.channel_product&.product_mapping&.product&.weight.to_f * quantity
        width = item&.channel_product&.product_mapping&.product&.width.to_f
        height = item&.channel_product&.product_mapping&.product&.height.to_f
        @service_label = MailServiceLabel.create(height: height, weight: weight,
                                                  length: length, width: width, assign_rule_id: @assign_rule.id)
      end
    end
    redirect_to order_dispatches_path(order_filter: 'ready')
  end

  def update_selected
    if params[:order_id].present? || params[:selected].present?
      order = ChannelOrder.find_by(id: params[:order_id])
      order&.update(selected: true)
      message = { result: true }
      message = { result: false, errors: order.errors.full_messages } if order.errors.any?
    else
      message = { result: 'error', message: 'Order not found' }
    end
    respond_to do |format|
      format.json { render json: message }
    end
  end

  def bulk_update_selected
    ChannelOrder.where(id: params[:selected]).update_all(selected: true)
    ChannelOrder.where(id: params[:unselected]).update_all(selected: false)
    message = { result: true, message: 'All orders updated' }
    respond_to do |format|
      format.json { render json: message }
    end
  end

  def import_order_file
    return unless params[:channel_order][:file].present?

    file = params[:channel_order][:file]
    file_type = file.present? ? file.path.split('.').last.to_s.downcase : ''
    if file.present? && (file_type.include? 'csv') || (file_type.include? 'xlsx')
      spreadsheet = open_spreadsheet(file)
      @header = spreadsheet.headers
      @data = []
      @import_mapping = ImportMapping.new
      @table_names = %w['Order Product']
      @db_names = ChannelOrder.column_names
      redirect_to new_import_mapping_path(db_columns: @db_names, header: @header, import_mapping: @import_mapping)
    else
      flash[:alert] = 'Try again file not match'
      redirect_to import_mappings_path
    end
  end

  def import
    file = params[:file]
    if file.present? && file.path.split('.').last.to_s.downcase == 'csv'
      csv_text = File.read(file).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
      convert = ImportMapping.where(sub_type: params[:mapping_type]).last.mapping_data.compact_blank.invert
      csv = CSV.parse(csv_text, headers: true, skip_blanks: true, header_converters: ->(name) { convert[name] })
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
    is_valid = (csv.headers.compact | ChannelOrder.column_names).sort == ChannelOrder.column_names.sort
    if is_valid
      @csv = csv
    else
      flash[:alert] = 'File not matched! Please change file'
    end
    if @csv.present?
      @csv.delete('id')
      @csv.delete('created_at')
      @csv.delete('updated_at')
      csv_create_records(@csv)
      flash[:notice] = 'File Upload Successful!'
    end
    redirect_to import_mappings_path
  end

  def refresh
    channel_order_items = ChannelOrderItem.where(channel_product_id: nil)
    channel_order_items.each do |item|
      product = ChannelProduct.find_by(item_sku: item.sku)
      item.update(channel_product_id: product&.id)
    end
    update_order_stage
    # job_data = AmazonOrderItemJob.perform_later
    JobStatus.create(name: 'AmazonOrderItemJob', status: 'inqueue', perform_in: 300)
    flash[:notice] = 'Channel Order Items updated!'
    redirect_to order_dispatches_path(order_filter: params[:order_filter])
  end

  def refresh_product
    orders = ChannelOrder.where(stage: 'ready_to_dispatch')
    orders.each do |order|
      order.channel_order_items.each do |item|
        product = item.channel_product&.product_mapping&.product || item.product
        product&.update(unshipped: (product.unshipped.to_i + item.ordered.to_i))
      end
    end
    redirect_to order_dispatches_path(order_filter: params[:order_filter])
  end

  def allocations
    order_items = ChannelOrder.find_by(id: params[:listing_id]).channel_order_items
    if params[:allocate].eql? 'true'
      order_items.each do |item|
        allocate_item(item)
      end
    else
      order_items.each do |item|
        unallocate_item(item)
      end
    end
    redirect_to request.referrer
  end

  def unallocate_item(order_item)
    product = order_item.channel_product.product_mapping.product
    return multipack_unallocation(order_item, product) if product.product_type.eql? 'multiple'

    product.update(available_stock: product.available_stock.to_f + order_item.ordered,
                   allocated: product.allocated.to_f - order_item.ordered, allocated_orders: product.allocated_orders.to_i - 1)
    #  change_log: "#{order_item.channel_order.channel_type} API, #{order_item.channel_order.id}, #{order_item.channel_order.order_id}, UnAllocate, #{order_item.channel_product.listing_id}")
    order_item.update(allocated: false)
    flash[:notice] = 'Unallocation successful!'
  end

  def allocate_item(order_item)
    product = order_item.channel_product.product_mapping.product
    return multipack_allocation(order_item, product) if product&.product_type.eql? 'multiple'

    if product&.available_stock.to_i >= order_item.ordered
      product.update(available_stock: product.available_stock.to_f - order_item.ordered,
                     allocated: product.allocated.to_f + order_item.ordered, allocated_orders: product.allocated_orders.to_i + 1)
      # change_log: "#{order_item.channel_order.channel_type} API, #{order_item.channel_order.id}, #{order_item.channel_order.order_id}, Allocated, #{order_item.channel_product.listing_id}")
      order_item.update(allocated: true)
    else
      @not_allocated.instance_of?(Array) ? (@not_allocated << order_item.channel_order&.order_id) : flash[:alert] = 'Available stock is not enough!'
    end
  end

  def multipack_unallocation(order_item, product)
    product.multipack_products.each do |multipack|
      child = multipack.child
      quantity = multipack.quantity
      ordered = (order_item.ordered * quantity)
      child.update(available_stock: child.available_stock.to_f + ordered,
                   allocated: child.allocated.to_f - ordered, allocated_orders: child.allocated_orders.to_i - 1)
      # ,change_log: "#{order_item.channel_order.channel_type} API, #{order_item.channel_order.id}, #{order_item.channel_order.order_id}, UnAllocate, #{order_item.channel_product.listing_id}"
    end
    order_item.update(allocated: false)
    flash[:notice] = 'Unallocation successful!'
  end

  def multipack_allocation(order_item, product)
    available = product.multipack_products.map { |m| m.child.available_stock.to_i }
    required = product.multipack_products.map { |m| m.quantity.to_i * order_item.ordered }
    check = available.zip(required).all? { |a, b| a >= b }
    if check
      product.multipack_products.each do |multipack|
        child = multipack.child
        quantity = multipack.quantity
        ordered = (order_item.ordered * quantity)
        child.update(available_stock: child.available_stock.to_f - ordered,
                     allocated: child.allocated.to_f + ordered, allocated_orders: child.allocated_orders.to_i + 1)
        # change_log: "#{order_item.channel_order.channel_type} API, #{order_item.channel_order.id}, #{order_item.channel_order.order_id}, Allocated, #{order_item.channel_product.listing_id}")
      end
      order_item.update(allocated: true)
    else
      @not_allocated.instance_of?(Array) ? (@not_allocated << order_item.channel_order&.order_id) : flash[:alert] = 'Available stock is not enough!'
    end
  end

  def allocate(product, ordered)
    product.update(available_stock: product.available_stock.to_f - ordered,
                   allocated: product.allocated.to_f + ordered)
    #  change_log: "#{order_item.channel_order.channel_type} API, #{order_item.channel_order.id}, #{order_item.channel_order.order_id}, Allocated, #{order_item.channel_product.listing_id}")
  end

  def version
    @order = ChannelOrder.find_by(id: params[:id])
    @versions = @order&.versions
  end

  def import_customer
    file = params[:file]
    if file.present? && file.path.split('.').last.to_s.downcase == 'csv'
      csv_text = File.read(file)
      csv = CSV.parse(csv_text, headers: true)
      # found_e, row_number = verify_csv_format(csv)
      # if found_e == false
      csv.each do |row|
        order = ChannelOrder.find_by(stage: 'ready_to_dispatch', order_id: row['order-id'])
        next unless order.present?
        next unless !row['buyer-phone-number']&.downcase&.include? 'e'

        order.buyer_name = row['buyer-name']
        order.build_system_user(user_type: 'customer', sales_channel: 'amazon', name: row['buyer-name'],
                                email: row['buyer-email'], phone_number: row['buyer-phone-number'],
                                days_for_order_to_completion: row['promise-date'].to_date - Date.today)
        order.system_user.addresses.build(
          address_title: 'delivery', company: row['ship-address-1'].to_s,
          address: row['ship-address-2'].to_s + row['ship-address-3'].to_s,
          city: row['ship-city'], region: row['ship-state'], postcode: row['ship-postal-code'].gsub(' ', ''),
          country: row['ship-country']
        )
        order.save
      end
      flash[:notice] = 'Customer imported successfuly'
      # else
      #   flash[:alert] = "Row number #{row_number} have issue in phone number."
      # end
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
    redirect_to request.referrer
  end

  def recalculate_rule
    orders = ChannelOrder.where(id: params[:orders])
    concern_recalculate_rule(orders)
  end

  def invoice
    @order = ChannelOrder.find_by(id: params[:id])
    @addresses = @order.system_user&.addresses
    @delivery_address = @addresses&.where(address_title: 'delivery').last
    @invoice_address = @addresses&.where(address_title: 'admin').last
    request.format = 'pdf'
    respond_to do |format|
      format.pdf do
        render pdf: 'invoice.pdf', viewport_size: '1280x1024', template: 'order_dispatches/invoice.pdf.erb'
      end
    end
  end

  def cancel_order
    order = ChannelOrder.find_by(id: params[:id])
    order_items = order.channel_order_items
      order_items.each do |item|
        cancel_unallocate_item(item)
      end
      order.update(stage: 'canceled')
      redirect_to request.referrer
  end

  def cancel_unallocate_item(order_item)
    product = order_item.channel_product.product_mapping.product
    return cancel_multipack_unallocation(order_item, product) if product.product_type.eql? 'multiple'

    inventory_balance = product.inventory_balance.to_i + order_item.ordered.to_i
    channel_type = order_item.channel_order.channel_type
    if order_item.allocated
      product.update(
        change_log: "Cancel Order, #{order_item.channel_product.item_sku}, #{order_item.channel_order.order_id},
        Cancel Order, #{order_item.channel_product.listing_id}, #{order_item.ordered.to_i}, #{inventory_balance},
        #{channel_type}", available_stock: product.available_stock.to_i + order_item.ordered.to_i,
        unshipped: product.unshipped.to_i - order_item.ordered.to_i, unshipped_orders: product.unshipped_orders.to_i - 1,
        allocated: product.allocated.to_i - order_item.ordered.to_i, allocated_orders: product.allocated_orders.to_i - 1
      )
    else
      product.update(
        change_log: "Cancel Order, #{order_item.channel_product.item_sku}, #{order_item.channel_order.order_id},
        Cancel Order, #{order_item.channel_product.listing_id}, #{order_item.ordered.to_i}, #{inventory_balance},
        #{channel_type}", available_stock: product.available_stock.to_i + order_item.ordered.to_i,
        unshipped: product.unshipped.to_i - order_item.ordered.to_i, unshipped_orders: product.unshipped_orders.to_i - 1
      )
    end
  end

  def cancel_multipack_unallocation(order_item, product)
    channel_type = order_item.channel_order.channel_type
    product.multipack_products.each do |multipack|
      child = multipack.child
      quantity = multipack.quantity
      ordered = (order_item.ordered * quantity)
      inventory_balance = child.inventory_balance.to_i + ordered
      if order_item.allocated
        child.update(
          change_log: "Cancel Order, #{order_item.channel_product.item_sku}, #{order_item.channel_order.order_id},
          Cancel Order, #{order_item.channel_product.listing_id}, #{ordered}, #{inventory_balance},
          #{channel_type}", available_stock: child.available_stock.to_f + ordered,
          unshipped: child.unshipped.to_i - ordered, unshipped_orders: child.unshipped_orders.to_i - 1,
          allocated: child.allocated.to_f - ordered, allocated_orders: child.allocated_orders.to_i - 1
        )
      else
        child.update(
          change_log: "Cancel Order, #{order_item.channel_product.item_sku}, #{order_item.channel_order.order_id},
          Cancel Order, #{order_item.channel_product.listing_id}, #{ordered}, #{inventory_balance},
          #{channel_type}", available_stock: child.available_stock.to_f + ordered,
          unshipped: child.unshipped.to_i - ordered, unshipped_orders: child.unshipped_orders.to_i - 1
        )
      end
    end
  end

  private

  def order_dispatches_params
    params.require(:channel_order)
          .permit(:buyer_name, :system_user_id, :channel_type, :order_status, :order_id, :refund_amount,
                  :concession_amount, :total_amount, :payment_status, :buyer_name, :channel_order_id,
                  :assign_rule_id, :system_user_id, :order_batch_id, :stage, :order_type,
                  channel_order_items_attributes:
                  %i[sku ordered product_id _destroy])
  end

  def csv_create_records(csv)
    csv.each do |row|
      row = row.to_hash
      row.delete(nil)
      order = ChannelOrder.new
      order.update(row)
    end
  end

  def open_spreadsheet(file)
    case File.extname(file.original_filename)
    when '.csv' then CSV.parse(File.read(file.path).force_encoding('ISO-8859-1').encode('utf-8', replace: nil),
                               headers: true)
    when '.xls' then  Roo::Excel.new(file.path, packed: nil, file_warning: :ignore)
    when '.xlsx' then Roo::Excelx.new(file.path, packed: nil, file_warning: :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def order_mapping_params; end

  def check_status
    @response_status = ChannelResponseData.all.pluck(:status)
    @status = 1
    @response_status.each do |response_status|
      @status = 0 if (response_status == 'error') || (response_status == 'not available')
    end
    @status = 3 if @response_status == []
  end

  # def params_check
  #   if params[:product_mapping].eql? 'Amazon Orders'
  #     @order_type = 'amazon'
  #   elsif params[:product_mapping].eql? 'Ebay Orders'
  #     @order_type = ['ebay']
  #   else
  #     @order_type = %w[ebay amazon]
  #   end
  # end

  def ransack_params
    @q = ChannelOrder.includes(:channel_order_items).ransack(params[:q])
    name = params[:q].try(:[], 'order_id_or_order_status_or_buyer_name_cont')&.gsub('', ' ')
    @channel_orders = ChannelOrder.joins(channel_order_items: :channel_product)
    .includes(channel_order_items: :channel_product)
    .where("REPLACE(channel_products.item_sku, ' ', '') ILIKE REPLACE('%#{name}%', ' ', '')") if name.present?
    @channel_orders = @q.result if @channel_orders.nil? || @channel_orders.empty?
    @channel_types = ChannelOrder.channel_types
    @channel_postages = ChannelOrder.pluck(:postage).uniq.compact
    @mail_service_rules = MailServiceRule.all
  end

  def unmatched_sku
    return unless params[:order_filter].eql? 'unprocessed'

    # @unmatched_sku = []
    @unmatched_sku_body = @channel_orders.where(stage: 'unable_to_find_sku')
                                         .order(created_at: :desc)
    @unmatched_sku = @unmatched_sku_body.page(params[:unmatched_page]).per(params[:limit] || 100)
    @matching_products = {}
    @un_matched_product_order.each do |order|
      order.channel_order_items.each do |item|
        matching = item&.channel_product&.status_mapped? ? item.channel_product.product_mapping&.product : Product.find_by('sku LIKE ?', "%#{item.sku}%")
        @matching_products[item.id] = matching if matching.present?
      end
    end
    return unless params[:export]

    orders = @un_matched_product_order_body + @unmatched_sku_body
    orders = ChannelOrder.where(id: orders.pluck(:id), selected: true) if params[:selected]
    export_csv(orders)
    respond_to do |format|
      format.html
      format.csv
    end
  end

  def completed_orders
    return unless params[:order_filter].eql? 'completed'

    @completed = @channel_orders.where(stage: 'completed')
    @completed_orders = @completed.order(created_at: :desc).distinct.page(params[:completed_page]).per(params[:limit] || 100)
    return unless params[:export]

    @completed = @completed.where(selected: true) if params[:selected]
    export_csv(@completed)
    respond_to do |format|
      format.html
      format.csv
    end
  end

  def no_sku
    return unless params[:order_filter].eql? 'issue'

    @issue = @channel_orders.where(stage: 'issue')
    @issue_orders = @issue.order(created_at: :desc).page(params[:orders_page]).per(params[:limit] || 100)
    return unless params[:export]

    @issue = @issue.where(selected: true) if params[:selected]
    export_csv(@issue)
    respond_to do |format|
      format.html
      format.csv
    end
  end

  def unpaid_orders
    return unless params[:order_filter].eql? 'unpaid'

    @unpaid_orders = @channel_orders.where(stage: %w[pending unpaid])
    @unpaid = @unpaid_orders.order(created_at: :desc).page(params[:unpaid_page]).per(params[:limit] || 100)
    return unless params[:export]

    @unpaid_orders = @unpaid_orders.where(selected: true) if params[:selected]
    export_csv(@unpaid_orders)
    respond_to do |format|
      format.html
      format.csv
    end
  end

  def not_started_orders
    return unless params[:order_filter].eql? 'ready'

    value = params[:id_or_order_id_or_order_status_or_buyer_name_or_channel_order_items_sku_cont]
    params[:q] = params[:q].merge(id_or_order_id_or_order_status_or_buyer_name_or_channel_order_items_sku_cont: value) if value.present?
    params[:q] = JSON.parse params[:q].gsub('=>', ':') if params[:q]&.include?('"')
    @search = @channel_orders.where(stage: 'ready_to_dispatch')
                             .where.not(channel_type: 'amazon', system_user_id: nil).search(params[:q])
    @not_started_orders = @search.result
    if params[:q].present? && params[:q][:s].present? && params[:q][:s].include?('total_amount')
      @not_started_orders = @not_started_orders.order(:total_amount)
    else
      @not_started_orders = @not_started_orders.order(:order_type, created_at: :desc)
    end
    @not_started_order_data = @not_started_orders.distinct.page(params[:not_started_page]).per(params[:limit] || 100)
    return unless (params[:order_filter].eql? 'ready') && params[:export]

    @not_started_orders = @not_started_orders.where(selected: true) if params[:selected]
    export_csv(@not_started_orders)
    respond_to do |format|
      format.html
      format.csv
    end
  end

  def unmatched_product_orders
    return unless params[:order_filter].eql? 'unprocessed'

    @un_matched_product_order_body = @channel_orders.where(stage: 'unmapped_product_sku')
                                                    .order(created_at: :desc)
    @un_matched_product_order = @un_matched_product_order_body.page(params[:unmatched_product_page]).per(params[:limit] || 100)
  end

  def ready_to_print_orders
    @orders = @channel_orders.where(stage: 'ready_to_print').order(created_at: :desc)
    return unless (params[:order_filter].eql? 'assignment') && params[:export]

    @orders = @orders.where(selected: true) if params[:selected]
    export_csv(@orders)
    respond_to do |format|
      format.html
      format.csv
    end
  end

  def customer_info
    return unless params[:order_filter].eql? 'customer_info'

    @search = @channel_orders.where(channel_type: 'amazon', stage: 'ready_to_dispatch', system_user_id: nil).search(params[:q])
    @missing_customer_detail = @search.result
    @missing_customer_detail = @missing_customer_detail.order(created_at: :desc)
    @missing_customer_orders = @missing_customer_detail.page(params[:page]).per(params[:limit] || 100)
  end

  def csv_export(orders)
    attributes = ChannelOrder.column_names.excluding('created_at', 'updated_at', 'order_data', 'product_scan')
    CSV.generate(headers: true) do |csv|
      headers = attributes.including('Delivery Name', 'Postcode')
      csv << headers
      orders.each do |channel_order|
        data = attributes.map { |attr| channel_order.send(attr) }
        data.map! { |x| x.nil? ? ' ' : x }
        delivery_name = channel_order.system_user&.addresses&.where(address_title: 'delivery')&.first&.name
        postcode = channel_order.system_user&.addresses&.where(address_title: 'delivery')&.first&.postcode
        data.push(delivery_name, postcode)
        csv << data
      end
    end
  end

  def load_counts
    @auto_dispatch = ImportMapping.where(table_name: 'Auto-dispatch').map { |s| [s.sub_type, s.id] }.to_h
    @total_products_count = ChannelProduct.count
    @issue_products_count = ChannelProduct.where(item_sku: nil).count
    @today_orders = @channel_orders.where('Date(channel_orders.created_at) = ?', Date.today).count
    @ready_to_pack_count = @channel_orders.where(stage: 'ready_to_print').count
    @not_started_order_count = @not_started_orders&.count || @channel_orders.where(stage: 'ready_to_dispatch')
                                              .where.not(channel_type: 'amazon', system_user_id: nil).distinct.count
    @issue_orders_count = @channel_orders.where(stage: 'issue').count
    @unpaid_orders_count = @channel_orders.where(stage: %w[unpaid pending]).count
    @completed_count = @channel_orders.where(stage: 'completed').distinct.count
    @un_matched_orders_count = @channel_orders.where(stage: 'unmapped_product_sku').count
    @unmatched_sku_count = @channel_orders.where(stage: 'unable_to_find_sku').count
    @miss_customer_count = @channel_orders.where(channel_type: 'amazon', stage: 'ready_to_dispatch', system_user_id: nil)
                                          .count
  end

  def update_order_stage
    ChannelOrder.where(order_status: %w[FULFILLED Shipped]).update_all(stage: 'completed')
    ChannelOrder.where(order_status: 'Canceled').update_all(stage: 'canceled')
    ChannelOrder.where(order_status: 'Pending').update_all(stage: 'pending')
    ChannelOrder.where(order_status: %w[NOT_STARTED Unshipped]).each do |order|
      extra_update_order_stage(order.channel_order_items.map { |i| i.channel_product&.status }, order)
      order.update(stage: 'issue') if order.channel_order_items.map(&:sku).any? nil
    end
  end

  def extra_update_order_stage(condition, order)
    if condition.any?(nil)
      order.update(stage: 'unable_to_find_sku')
    elsif condition.any?('unmapped')
      order.update(stage: 'unmapped_product_sku')
    else
      order.update(stage: 'ready_to_dispatch')
    end
  end

  def bulk_allocation
    orders = ChannelOrder.where(id: params[:object_ids])
    @not_allocated = []
    orders.each do |order|
      order.channel_order_items.each do |item|
        next if item.allocated

        allocate_item(item)
      end
      flash[:notice] = 'Allocation successful'
    end
    flash[:alert] = "Allocation failed for #{@not_allocated}. Available stock not enough" if @not_allocated.present?
    redirect_to request.referrer
  end

  def verify_csv_format(csv)
    found_e = false
    row_number = 1
    csv.each do |row|
      row_number += 1
      if row['buyer-phone-number']&.downcase&.include? 'e'
        found_e = true
        break
      end
    end
    [found_e, row_number]
  end
end
