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
    all_order_data if params[:orders_api].present?
    @assign_rule = AssignRule.new
    @assign_rule.mail_service_labels.build
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
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data csv_export(orders), filename: "orders-#{Date.today}.csv" }
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
      message = { result: order.selected, message: 'Order Updated!' }
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

  private

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
  end

  def unmatched_sku
    return unless params[:order_filter].eql? 'unprocessed'

    # @unmatched_sku = []
    @unmatched_sku_body = @channel_orders.joins(:channel_order_items)
                                         .where.not('channel_order_items.sku': [nil, @data])
                                         .where.not(order_status: %w[FULFILLED Shipped Pending])
                                         .order(created_at: :desc).distinct
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

    @completed = @channel_orders.where('order_status in (?)', %w[FULFILLED Shipped]).distinct
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

    @issue = @channel_orders.joins(:channel_order_items).where('channel_order_items.sku': nil)
                                   .where.not(order_status: %w[FULFILLED Shipped Pending])
    @issue_orders = @issue.order(created_at: :desc).distinct.page(params[:orders_page]).per(params[:limit])
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

    @unpaid_orders = @channel_orders.where(payment_status: 'UNPAID')
                                    .or(@channel_orders.where(order_status: 'Pending')).distinct
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
                            .joins(:channel_order_items, assign_rule: [mail_service_rule: :service])
                            .where('mail_service_rules.rule_name LIKE ? OR services.name LIKE ? and order_status = ?',
                                   "%#{params['assign_rule_name']}%", "%#{params['assign_rule_name']}%", 'NOT_STARTED')
                            .where('channel_order_items.sku': [@product_data]) - @un_matched_product_order).uniq
    else
      @not_started_orders = (@channel_orders.joins(:channel_order_items).where(order_status: 'NOT_STARTED')
                                           .where.not('channel_order_items.sku': [nil, @unmatch_product_data]) - @un_matched_product_order).uniq
    end
    @not_started_orders = @not_started_orders.sort_by(&:created_at).reverse!
    @not_started_order_data = Kaminari.paginate_array(@not_started_orders).page(params[:not_started_page]).per(params[:limit])
    return unless (params[:order_filter].eql? 'ready') && params[:export]

    @not_started_orders = ChannelOrder.where(id: @not_started_orders.pluck(:id), selected: true) if params[:selected]
    export_csv(@not_started_orders)
    respond_to do |format|
      format.html
      format.csv
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
