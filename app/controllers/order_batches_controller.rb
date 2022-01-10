# frozen_string_literal: true

# dashboard
class OrderBatchesController < ApplicationController
  def new; end

  def create
    @order_batch = OrderBatch.new(order_batch_params)
    if @order_batch.save
      ChannelOrder.where(id: params[:order_ids].split(',')).update_all(ready_to_print: true)
      params[:notice] = 'Order Batch created successfully'
    else
      params[:alert] = @order_batch.errors.full_messages
    end
    redirect_to order_dispatches_path(order_filter: 'ready')
  end

  private

  def order_batch_params
    params.require(:order_batch).permit(
      :pick_preset, :print_packing_list, :print_packing_list_option, :mark_as_picked, :print_courier_labels,
      :print_invoice, :update_channels, :mark_order_as_dispatched, :batch_name, :shipping_rule_max_weight,
      :overwrite_order_notes
    )
  end
end
