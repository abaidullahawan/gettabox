# frozen_string_literal: true

# dashboard
class OrderBatchesController < ApplicationController
  before_action :session_batch, only: %i[create]

  def new; end

  def create
    # @order_batch = OrderBatch.find_or_initialize_by(batch_name: params[:order_batch][:batch_name])
    orders = ChannelOrder.joins(:channel_order_items).where(id: params[:order_ids].split(',')).order(sku: :asc)
    stage = order_batch_params[:mark_order_as_dispatched].to_i.positive? ? 'completed' : 'ready_to_print'
    if params['commit'].eql? 'save'
      @order_batch = OrderBatch.create(order_batch_params)
      @order_batch.update(pick_preset: params['name_of_template'], preset_type: 'pick_preset')
    elsif order_batch_params[:print_courier_labels].to_i.zero?
      print_packing_list if order_batch_params[:print_packing_list].to_i.positive?
      update_channels if order_batch_params[:update_channels].to_i.positive?
      mark_order_as_dispatched(stage) if order_batch_params[:mark_order_as_dispatched].to_i.positive?
      update_batch(stage)
      # orders.update_all(stage: 'ready_to_print', order_batch_id: @order_batch.id)
    elsif check_rule(orders.first) && order_batch_params[:print_courier_labels].to_i.positive?
      courier_csv_export(orders)
      unless orders.first.assign_rule.mail_service_rule.tracking_import
        update_channels if order_batch_params[:update_channels].to_i.positive?
        mark_order_as_dispatched(stage) if order_batch_params[:mark_order_as_dispatched].to_i.positive?
        update_batch(stage)
      end
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
      headers = @export_mapping.mapping_data.compact_blank.keys
      @csv = CSV.generate(headers: true) do |csv|
        csv << headers
        orders.each do |order|
          skus = []
          next unless order.assign_rule.mail_service_rule.export_mapping_id == rule

          order&.channel_order_items&.each do |item|
            if item.channel_product&.product_mapping&.product&.product_type_multiple?
              item.channel_product&.product_mapping&.product&.multipack_products&.each do |multipack_product|
                product_sku = multipack_product&.child&.sku
                product_quantity = multipack_product.quantity * item.ordered.to_i
                skus << "#{product_quantity.to_i}x #{product_sku}"
              end
            else
              product_sku = item.channel_product&.product_mapping&.product&.sku
              product_quantity = item.ordered.to_i
              skus << "#{product_quantity.to_i}x #{product_sku}"
            end
          end
          # order.update(stage: 'ready_to_print')
          order_csv = channel_order_data.map { |k, v| [k.to_s, order.send(v)] }.to_h
          item_csv = channel_order_item_data.map { |k, v| [k.to_s, order.channel_order_items.first.send(v)] }.to_h
          address_csv = address_data.map { |k, v| [k.to_s, order.system_user&.addresses&.find_by(address_title: 'delivery')&.send(v)] }.to_h
          system_user_csv = system_user_data.map { |k, v| [k.to_s, order.system_user&.send(v)] }.to_h
          label_csv = mail_service_label_data.map { |k, v| [k.to_s, order.assign_rule.mail_service_labels.first.send(v)] }.to_h
          service_rule_csv = mail_service_rule_data.map { |k, v| [k.to_s, order.assign_rule&.mail_service_rule.send(v)] }.to_h
          all_datum = [*item_csv, *order_csv, *label_csv, *address_csv, *system_user_csv, *service_rule_csv].to_h
          order.assign_rule.mail_service_labels.each_with_index do |weigth_label_csv, index|
            row = []
            all_datum.each do |key, value|
              row[headers.find_index(key)] =
                case key
                when 'Weight'
                  weigth_label_csv.weight.to_f / 1000
                when 'Height'
                  weigth_label_csv.height.to_f
                when 'Length'
                  weigth_label_csv.length.to_f
                when 'Width'
                  weigth_label_csv.width.to_f
                when 'Reference'
                  index.positive? ? "#{value} copy#{index}" : value
                when 'SKU'
                  skus.join(' + ')
                # when 'Quantity'
                #   product_quantity.join(' + ')
                else
                  value || ' '
                end
            end
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

  def print_packing_list
    order_ids = params[:order_ids]
    order_ids = order_ids.split(',')
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

    credential = Credential.find_by(grant_type: 'wait_time')
    wait_time = credential.created_at
    wait_time = DateTime.now > wait_time ? DateTime.now + 120.seconds : wait_time + 120.seconds
    credential.update(redirect_uri: 'AmazonTrackingJob', authorization: order_ids, created_at: wait_time)
    elapsed_seconds = wait_time - DateTime.now

    # AmazonTrackingJob.set(wait: elapsed_seconds.seconds).perform_later(order_ids: order_ids)
    JobStatus.create(name: 'AmazonTrackingJob', status: 'inqueue', arguments: { order_id: order_ids }, perform_in: elapsed_seconds.seconds)
    # job_data = EbayCompleteSaleJob.set(wait: 5.minutes).perform_later(order_ids: order_ids)
    JobStatus.create(name: 'EbayCompleteSaleJob', status: 'inqueue', arguments: { order_ids: order_ids }, perform_in: 300)
  end

  def mark_order_as_dispatched(stage)
    order_ids = params[:order_ids]
    order_ids = order_ids.split(',')
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
    orders.update_all(stage: stage)
    return unless order_batch_params[:print_packing_list].to_i.zero?

    flash[:notice] = 'Order completed successfully.'
    redirect_to request.referrer
  end

  def update_batch(stage)
    order_ids = params[:order_ids]
    order_ids = order_ids.split(',')
    session[:batch_params]['batch_name'] = 'unbatch orders' if session[:batch_params]['mark_as_batch_name'].to_i.zero?
    batch = OrderBatch.find_or_initialize_by(batch_name: session[:batch_params]['batch_name'])
    update_session = session[:batch_params].merge(preset_type: 'batch_name')
    batch.update(update_session)
    order_ids.each do |id|
      order = ChannelOrder.find_by(id: id)
      order.update(stage: stage, order_batch_id: batch.id, change_log: "Order Exported, #{order.id}, #{order.order_id}, #{current_user.personal_detail.full_name}")
      order.update(change_log: "Channel Updated, #{order.id}, #{order.order_id}, #{current_user.personal_detail&.full_name}") if batch.update_channels
    end
  end
end
