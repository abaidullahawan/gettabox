# frozen_string_literal: true

# dashboard
class OrderBatchesController < ApplicationController
  before_action :session_batch, only: %i[create]

  def new; end

  def create
    # @order_batch = OrderBatch.find_or_initialize_by(batch_name: params[:order_batch][:batch_name])
    orders = ChannelOrder.where(id: params[:order_ids].split(','))
    if params['commit'].eql? 'save'
      @order_batch = OrderBatch.create(order_batch_params)
      @order_batch.update(pick_preset: params['name_of_template'], preset_type: 'pick_preset')
    elsif order_batch_params[:print_courier_labels].to_i.zero?
      print_packing_list if order_batch_params[:print_packing_list].to_i.positive?
      update_channels if order_batch_params[:update_channels].to_i.positive?
      mark_order_as_dispatched if order_batch_params[:mark_order_as_dispatched].to_i.positive?
      # orders.update_all(stage: 'ready_to_print', order_batch_id: @order_batch.id)
    elsif check_rule(orders.first) && order_batch_params[:print_courier_labels].to_i.positive?
      courier_csv_export(orders)
    else
      flash[:alert] = 'Only Manual Dispatch orders can be printed'
      redirect_to order_dispatches_path(order_filter: 'ready')
    end
  end

  def search_batch
    batches = OrderBatch.where('lower(batch_name) LIKE ?', "%#{params[:search_value]}%").where.not(batch_name: 'unbatch orders').pluck(:id, :batch_name)
    respond_to do |format|
      format.json { render json: batches }
    end
  end

  def set_pick_preset
    @order_batch_selected = OrderBatch.where(id: params['id'], preset_type: 'pick_preset')
    respond_to do |format|
      format.json { render json: @order_batch_selected }
    end
  end

  def save_batch_name
    batch = OrderBatch.find_by(batch_name: params[:batch_name])
    message = 'Batch already exists' if batch.present?
    respond_to do |format|
      format.json { render json: { message: message } }
    end
  end

  private

  def order_batch_params
    params.require(:order_batch).permit(
      :pick_preset, :print_packing_list, :print_packing_list_option, :mark_as_picked, :print_courier_labels,
      :print_invoice, :update_channels, :mark_order_as_dispatched, :batch_name, :shipping_rule_max_weight,
      :overwrite_order_notes, :save_batch_name, :mark_as_batch_name
    )
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
      mail_service_rule_data = {}
      @export_mapping.mapping_data.compact_blank.each do |key, attribute|
        channel_order_data[key] = attribute if ChannelOrder.column_names.include? attribute
        channel_order_item_data[key] = attribute if ChannelOrderItem.column_names.excluding(to_be_ignored).include? attribute
        address_data[key] = attribute if Address.column_names.excluding(to_be_ignored).include? attribute
        system_user_data[key] = attribute if SystemUser.column_names.excluding(to_be_ignored).include? attribute
        mail_service_label_data[key] = attribute if MailServiceLabel.column_names.excluding(to_be_ignored).include? attribute
        mail_service_rule_data[key] = attribute if MailServiceRule.column_names.excluding(to_be_ignored).include? attribute

      end
      attributes = channel_order_item_data.keys + channel_order_data.keys + mail_service_label_data.keys + address_data.keys + system_user_data.keys + mail_service_rule_data.keys
      attributes = attributes.clear.including('Item Name', 'Value', 'Reference', 'Quantity', 'Weight', 'Height', 'Length', 'Width',	'Name',	'Property', 'Street', 'Locality', 'Town', 'County', 'Postcode', 'Telephone', 'Email', 'SKU')
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        orders.each do |order|
          next unless order.assign_rule.mail_service_rule.export_mapping_id == rule

          # order.update(stage: 'ready_to_print')
          order_csv = channel_order_data.values.map { |attr| order.send(attr) }
          item_csv = channel_order_item_data.values.map { |attr| order.channel_order_items.first.send(attr) }
          address_csv = address_data.values.map { |attr| order.system_user&.addresses&.find_by(address_title: 'delivery')&.send(attr) }
          system_user_csv = system_user_data.values.map { |attr| order.system_user&.send(attr) }
          label_csv = mail_service_label_data.values.map { |attr| order.assign_rule.mail_service_labels.first.send(attr) }
          service_rule_csv = mail_service_rule_data.values.map { |attr| order.assign_rule&.mail_service_rule.send(attr) }
          order.assign_rule.mail_service_labels.each_with_index do |weigth_label_csv, index|
            row = csv_order(item_csv, order_csv, label_csv, address_csv, system_user_csv, service_rule_csv)
            row[4] = weigth_label_csv.weight.to_f / 1000
            row[5] = weigth_label_csv.height.to_f
            row[6] = weigth_label_csv.width.to_f
            row[7] = weigth_label_csv.length.to_f
            row[2] = "#{row[2]} [Copied]" if index.positive?
            csv << row
          end
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "#{rule_name}-#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}.csv" }
      end
      # flash[:alert] = 'Courier CSV Export Done!'
    else
      flash[:alert] = 'Please select order with same template'
      redirect_to order_dispatches_path(order_filter: 'ready')
    end
  end

  def check_rule(order)
    return false unless order.assign_rule&.mail_service_rule&.courier&.name.eql? 'Manual Dispatch'

    true
  end

  def session_batch
    session[:order_ids] = params[:order_ids]
    session[:batch_params] = order_batch_params.to_h
    session[:save_batch] = params[:save_batch_name].present?
  end

  def csv_order(item_csv, order_csv, label_csv, address_csv, system_user_csv, service_rule_csv)
    row = item_csv + order_csv + label_csv + address_csv + system_user_csv + service_rule_csv
    row[1], row[3] = row[3], row[1]
    row[2], row[4] = row[4], row[2]
    row[4], row[17] = row[17], row[4]
    row[4], row[8] = row[8], row[4]
    row[4], row[6] = row[6], row[4]
    row[5], row[7] = row[7], row[5]
    row[7], row[9] = row[9], row[7]
    row[8], row[9] = row[9], row[8]
    row[9], row[10] = row[10], row[9]
    row[10], row[11] = row[11], row[10]
    row[11], row[12] = row[12], row[11]
    row[12], row[13] = row[13], row[12]
    row[13], row[14] = row[14], row[13]
    row[14], row[15] = row[15], row[14]
    row[15], row[16] = row[16], row[15]
    row[4] = row[4].to_f / 1000
    row[16] = row[16].gsub(';', ' + ')
    row
  end

  def print_packing_list
    order_ids = params[:order_ids]
    multiple_products = ChannelOrderItem.where(channel_order_id: order_ids).joins(channel_product: [product_mapping: :product]).where("products.product_type": "multiple").uniq
    single_products = ChannelOrderItem.where(channel_order_id: order_ids).joins(channel_product: [product_mapping: :product]).where("products.product_type": "single").uniq
    products = []
    multiple_products.each do |multiple_product|
      multiple_product.channel_product.product_mapping.product.multipack_products.each do |multi|
        product = multi.child
        # quantity = multi.quantity.to_f * (product.pack_quantity.nil? ? 1 : product.pack_quantity.to_f)
        # products << { sku: product.sku, product: product, quantity: quantity * multiple_product.ordered }
        products << { sku: product.sku, product: product, quantity: multi.quantity.to_f * multiple_product.ordered }
      end
    end

    single_products.each do |single_product|
      product = single_product.channel_product.product_mapping.product
      # quantity = single_product.ordered * (product.pack_quantity.nil? ? 1 : product.pack_quantity.to_f)
      # products << { sku: product.sku, product: product, quantity: quantity }
      products << { sku: product.sku, product: product, quantity: single_product.ordered.to_i }
    end

    @products_group = products.group_by { |d| d[:sku] }
    request.format = 'pdf'
    respond_to do |format|
      format.pdf do
        render pdf: 'file.pdf', viewport_size: '1280x1024', template: 'order_dispatches/channel_product.pdf.erb'
      end
    end
  end

  def update_channels
    order_ids = params[:order_ids].split(',')
    AmazonTrackingJob.perform_later(order_ids: order_ids)
    EbayCompleteSaleJob.perform_later(order_ids: order_ids)
  end

  def mark_order_as_dispatched
    order_ids = params[:order_ids]
    multiple_products = ChannelOrderItem.where(channel_order_id: order_ids).joins(channel_product: [product_mapping: :product]).where("products.product_type": 'multiple').uniq
    single_products = ChannelOrderItem.where(channel_order_id: order_ids).joins(channel_product: [product_mapping: :product]).where("products.product_type": 'single').uniq
    multiple_products.each do |multiple_product|
      ordered_quantity = multiple_product.ordered
      multiple_product.channel_product.product_mapping.product.multipack_products.each do |multi|
        product = multi.child
        quantity = ordered_quantity.to_i * multi.quantity.to_i
        unshipped = product.unshipped.to_i - quantity
        allocated = product.allocated.to_i - quantity
        total_stock = product.total_stock.to_i - quantity
        unshipped_orders = product.unshipped_orders.to_i - 1
        allocated_orders = product.allocated_orders.to_i - 1
        product.update(unshipped: unshipped, allocated: allocated, total_stock: total_stock, unshipped_orders: unshipped_orders, allocated_orders: allocated_orders)
      end
    end
    single_products.each do |single_product|
      ordered_quantity = single_product.ordered
      product = single_product.channel_product.product_mapping.product
      unshipped = product.unshipped.to_i - ordered_quantity.to_i
      allocated = product.allocated.to_i - ordered_quantity.to_i
      total_stock = product.total_stock.to_i - ordered_quantity.to_i
      unshipped_orders = product.unshipped_orders.to_i - 1
      allocated_orders = product.allocated_orders.to_i - 1
      product.update(unshipped: unshipped, allocated: allocated, total_stock: total_stock, unshipped_orders: unshipped_orders, allocated_orders: allocated_orders)
    end
    orders = ChannelOrder.where(id: params[:order_ids].split(','))
    orders.update_all(stage: 'completed')
    return unless order_batch_params[:print_packing_list].to_i.zero?

    flash[:notice] = 'Order completed successfully.'
    redirect_to request.referrer
  end
end
