# frozen_string_literal: true

# Getting new orders and creating
class OrderDispatchesController < ApplicationController
  include NewProduct
  before_action :authenticate_user!
  # before_action :refresh_token, :refresh_token_amazon, only: %i[index all_order_data]
  before_action :check_status, only: %i[index fetch_response_orders]
  before_action :ransack_params, :load_counts, :unmatched_product_orders, :completed_orders, :no_sku,
                :not_started_orders, :unpaid_orders, :unmatched_sku, only: %i[index]
  before_action :new_product, :product_load_resources, :first_or_create_category, only: %i[index]

  def index
    @order_exports = ExportMapping.where(table_name: 'ChannelOrder')
    all_order_data if params[:orders_api].present?
    @assign_rule = AssignRule.new
    @assign_rule.mail_service_labels.build
    @order_batch = OrderBatch.new
  end

  def show; end

  def create; end

  def all_order_data
    if params[:amazon]
      AmazonOrderJob.perform_later
      flash[:notice] = 'Amazon order job created!'
    else
      CreateChannelOrderResponseJob.perform_later
      flash[:notice] = 'CALL sent to eBay API'
    end
    redirect_to order_dispatches_path(order_filter: 'unprocessed')
  end

  def export_csv(orders)
    if params[:export_mapping].present?
      @export_mapping = ExportMapping.find(params[:export_mapping])
      attributes = @export_mapping.export_data
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        orders.each do |order|
          csv << attributes.map { |attr| order.send(attr) }
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
      rule_name = ExportMapping.find_by(id: rule).sub_type
      @export_mapping = ExportMapping.find_by(id: rule)
      channel_order = []
      channel_order_item = []
      address = []
      system_user = []
      mail_service_label = []
      @export_mapping.mapping_data.compact_blank.each_value do |attribute|
        channel_order.push(attribute) if ChannelOrder.column_names.include? attribute
        channel_order_item.push(attribute) if ChannelOrderItem.column_names.include? attribute
        address.push(attribute) if Address.column_names.include? attribute
        system_user.push(attribute) if SystemUser.column_names.include? attribute
        mail_service_label.push(attribute) if MailServiceLabel.column_names.include? attribute
      end
      attributes = channel_order + channel_order_item + address + system_user + mail_service_label
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        orders.each do |order|
          if order.assign_rule.mail_service_rule.export_mapping_id == rule
            order_data = channel_order.map { |attr| order.send(attr) }
            item_data = channel_order_item.map { |attr| order.channel_order_items.first.send(attr) }
            address_data = address.map { |attr| order.system_user.addresses.find_by(address_title: 'delivery').send(attr) }
            system_user_data = system_user.map { |attr| order.system_user.send(attr) }
            label_data = mail_service_label.map { |attr| order.assign_rule.mail_service_labels.first.send(attr) }
            csv << order_data + item_data + system_user_data + address_data + label_data
          end
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "#{rule_name}.csv" }
      end
    else
      flash[:alert] = 'Please select order with same template'
      redirect_to order_dispatches_path(order_filter: 'ready')
    end
  end

  def fetch_response_orders
    if @status.zero?
      flash[:notice] = 'Please CALL eBay Orders.'
    else
      CreateChannelOrderJob.perform_later
      flash[:notice] = 'eBay Orders are saving . . .'
    end
    redirect_to order_dispatches_path(order_filter: 'unprocessed')
  end

  def bulk_method
    return unless params[:object_ids].excluding('0').present?

    @assign_rule = AssignRule.create(mail_service_rule_id: params[:rule_id], save_later: true)
    @service_label = MailServiceLabel.create(height: params[:height], weight: params[:weight], length: params[:length], width: params[:width], assign_rule_id: @assign_rule.id)
    order_ids = params[:object_ids].excluding('0')
    order_ids.each do |order|
      channel_order = ChannelOrder.find(order)
      channel_order&.update(assign_rule_id: @assign_rule.id)
    end
    redirect_to order_dispatches_path(order_filter: 'ready')
    flash[:notice] = 'Mail Service Rule Assigned!'
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
    redirect_to order_dispatches_path(order_filter: 'ready')
    flash[:notice] = 'Mail Service Rule Assigned!'
  end

  def update_selected
    if params[:order_id].present? && params[:selected].present?
      order = ChannelOrder.find_by(id: params[:order_id])
      order&.update(selected: params[:selected])
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
      csv = CSV.parse(csv_text, headers: true, skip_blanks: true, header_converters: lambda { |name| convert[name] })
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
    flash[:notice] = 'Channel Order Items updated!'
    redirect_to order_dispatches_path(order_filter: params[:order_filter])
  end

  private

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
    when '.csv' then CSV.parse(File.read(file.path).force_encoding('ISO-8859-1').encode('utf-8', replace: nil), headers: true)
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
    @q = ChannelOrder.ransack(params[:q])
    @channel_orders = @q.result
    @channel_types = ChannelOrder.channel_types
    @mail_service_rules = MailServiceRule.all
  end

  def unmatched_sku
    return unless params[:order_filter].eql? 'unprocessed'

    # @unmatched_sku = []
    @unmatched_sku_body = @channel_orders.joins(:channel_order_items).includes(:channel_order_items)
                                         .where.not('channel_order_items.sku': [nil, @data])
                                         .where.not(order_status: %w[FULFILLED Shipped Pending])
                                         .order(created_at: :desc)
    @unmatched_sku = @unmatched_sku_body.page(params[:unmatched_page]).per(params[:limit])
    @matching_products = {}
    @un_matched_product_order.each do |order|
      order.channel_order_items.each do |item|
        matching = Product.find_by('sku LIKE ?', "%#{item.sku}%")
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

    @completed = @channel_orders.joins(:channel_order_items).includes(:channel_order_items)
                                .where('order_status in (?)', %w[FULFILLED Shipped])
    @completed_orders = @completed.order(created_at: :desc).page(params[:completed_page]).per(params[:limit])
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

    @issue = @channel_orders.joins(:channel_order_items).includes(:channel_order_items)
                            .where('channel_order_items.sku': nil)
                            .where.not(order_status: %w[FULFILLED Shipped Pending])
    @issue_orders = @issue.order(created_at: :desc).page(params[:orders_page]).per(params[:limit])
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

    @unpaid_orders = @channel_orders.joins(:channel_order_items).includes(:channel_order_items)
                                    .where(payment_status: 'UNPAID')
                                    .or(@channel_orders.joins(:channel_order_items).includes(:channel_order_items)
                                    .where(order_status: 'Pending'))
    @unpaid = @unpaid_orders.order(created_at: :desc).page(params[:unpaid_page]).per(params[:limit])
    return unless params[:export]

    @unpaid_orders = @unpaid_orders.where(selected: true) if params[:selected]
    export_csv(@unpaid_orders)
    respond_to do |format|
      format.html
      format.csv
    end
  end

  def not_started_orders
    # return unless params[:order_filter].eql? 'ready'

    if params['assign_rule_name'].present?
      @not_started_orders = (@channel_orders
        .joins(channel_order_items: [channel_product: :product_mapping], assign_rule: [mail_service_rule: :service])
        .includes(channel_order_items: [channel_product: :product_mapping], assign_rule: [mail_service_rule: :service])
        .where('mail_service_rules.rule_name LIKE ? OR services.name LIKE ? and order_status = ?',
               "%#{params['assign_rule_name']}%", "%#{params['assign_rule_name']}%", 'NOT_STARTED')
        .where('channel_order_items.sku': [@product_data]) - @un_matched_product_order).uniq
    else
      @not_started_orders = (@channel_orders
        .joins(:channel_order_items).where(order_status: 'NOT_STARTED')
        .where.not('channel_order_items.sku': [nil, @unmatch_product_data]) - @un_matched_product_order).uniq
    end
    @not_started_orders = @not_started_orders.sort_by(&:created_at).reverse!
    @not_started_order_data = Kaminari
                              .paginate_array(@not_started_orders).page(params[:not_started_page]).per(params[:limit])
    return unless (params[:order_filter].eql? 'ready') && params[:export]

    @not_started_orders = ChannelOrder.where(id: @not_started_orders.pluck(:id), selected: true) if params[:selected]
    if params[:courier_csv].present?
      courier_csv_export(@not_started_orders)
    else
      export_csv(@not_started_orders)
      respond_to do |format|
        format.html
        format.csv
      end
    end
  end

  def unmatched_product_orders
    # return unless params[:order_filter].eql? 'unprocessed'

    @un_matched_product_order_body = @channel_orders.joins(:channel_order_items)
                                                    .where('channel_order_items.sku': @unmatch_product_data)
                                                    .where.not(order_status: %w[FULFILLED Shipped Pending])
                                                    .order(created_at: :desc).distinct
    @un_matched_product_order = @un_matched_product_order_body.page(params[:unmatched_product_page]).per(params[:limit])
  end

  def csv_export(orders)
    attributes = ChannelOrder.column_names.excluding('created_at', 'updated_at')
    CSV.generate(headers: true) do |csv|
      csv << attributes
      orders.each do |channel_order|
        row = channel_order.attributes.values_at(*attributes)
        csv << row
      end
    end
  end

  def load_counts
    @total_products_count = ChannelProduct.count
    @issue_products_count = ChannelProduct.where(item_sku: nil).count
    @unmatch_product_data = ChannelProduct.where(status: 'unmapped').pluck(:item_sku).compact
    @product_data = ChannelProduct.where(status: 'mapped').pluck(:item_sku).compact
    @data = ChannelProduct.pluck(:item_sku).compact
    @today_orders = @channel_orders.where('Date(created_at) = ?', Date.today).distinct.count
    @issue_orders_count = @channel_orders.joins(:channel_order_items).where('channel_order_items.sku': nil)
                                         .where.not(order_status: %w[FULFILLED Shipped]).distinct.count
    @unpaid_orders_count = @channel_orders.where(payment_status: 'UNPAID')
                                          .or(@channel_orders.where(order_status: 'Pending')).distinct.count
    @completed_count = @channel_orders.where('order_status in (?)', %i[FULFILLED Shipped]).distinct.count
    @un_matched_orders_count = @channel_orders.joins(:channel_order_items)
                                              .where('channel_order_items.sku': @unmatch_product_data)
                                              .where.not(order_status: %w[FULFILLED Shipped Pending]).distinct.count
    @unmatched_sku_count = @channel_orders.joins(:channel_order_items)
                                          .where.not('channel_order_items.sku': @data)
                                          .where.not(order_status: %w[FULFILLED Shipped Pending]).distinct.count
  end
end
