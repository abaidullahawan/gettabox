# frozen_string_literal: true

# dashboard
class OrderBatchesController < ApplicationController
  before_action :session_batch, only: %i[create]

  def new; end

  def create
    # @order_batch = OrderBatch.find_or_initialize_by(batch_name: params[:order_batch][:batch_name])
    orders = ChannelOrder.where(id: params[:order_ids].split(','))
    if order_batch_params[:print_courier_labels] && check_rule(orders.first)
      courier_csv_export(orders)
      # orders.update_all(stage: 'ready_to_print', order_batch_id: @order_batch.id)
    else
      flash[:alert] = 'Only Manual Dispatch orders can be printed'
      redirect_to order_dispatches_path(order_filter: 'ready')
    end
  end

  def search_batch
    batches = OrderBatch.where('lower(batch_name) LIKE ?', "%#{params[:search_value]}%").pluck(:id, :batch_name)
    respond_to do |format|
      format.json { render json: batches }
    end
  end

  private

  def order_batch_params
    params.require(:order_batch).permit(
      :pick_preset, :print_packing_list, :print_packing_list_option, :mark_as_picked, :print_courier_labels,
      :print_invoice, :update_channels, :mark_order_as_dispatched, :batch_name, :shipping_rule_max_weight,
      :overwrite_order_notes
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
      @export_mapping.mapping_data.compact_blank.each do |key, attribute|
        channel_order_data[key] = attribute if ChannelOrder.column_names.include? attribute
        channel_order_item_data[key] = attribute if ChannelOrderItem.column_names.excluding(to_be_ignored).include? attribute
        address_data[key] = attribute if Address.column_names.excluding(to_be_ignored).include? attribute
        system_user_data[key] = attribute if SystemUser.column_names.excluding(to_be_ignored).include? attribute
        mail_service_label_data[key] = attribute if MailServiceLabel.column_names.excluding(to_be_ignored).include? attribute
      end
      attributes = system_user_data.keys + channel_order_item_data.keys + mail_service_label_data.keys + address_data.keys + channel_order_data.keys
      attributes[1], attributes[15] = attributes[15], attributes[1]
      attributes[2], attributes[16] = attributes[16], attributes[2]
      attributes[4], attributes[17] = attributes[17], attributes[4]
      attributes[4], attributes[5] = attributes[5], attributes[4]
      attributes[5], attributes[6] = attributes[6], attributes[5]
      attributes[6], attributes[7] = attributes[7], attributes[6]
      attributes[7], attributes[8] = attributes[8], attributes[7]
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
          row = system_user_csv + item_csv + label_csv + address_csv + order_csv
          row[1], row[15] = row[15], row[1]
          row[2], row[16] = row[16], row[2]
          row[4], row[17] = row[17], row[4]
          row[4], row[5] = row[5], row[4]
          row[5], row[6] = row[6], row[5]
          row[6], row[7] = row[7], row[6]
          row[7], row[8] = row[8], row[7]
          csv << row
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "#{rule_name}.csv" }
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
  end
end
