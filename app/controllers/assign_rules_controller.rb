# frozen_string_literal: true

# AssignRule
class AssignRulesController < ApplicationController

    def index; end
  def create
    @assign_rule = AssignRule.new(assign_rule_params)
    if @assign_rule.save
        if params[:assign_rule][:save_later] == '1'
            ChannelOrder.find(params[:channel_order_id])&.channel_order_items&.each do |order_item|
                ChannelProduct.where(item_sku: order_item.sku).update_all(assign_rule_id: @assign_rule.id)
                ChannelOrderItem.where(sku: order_item.sku).update_all(assign_rule_id: @assign_rule.id)
            end
        else
            ChannelOrder.find(params[:channel_order_id])&.channel_order_items&.each do |order_item|
                order_item.update(assign_rule_id: @assign_rule.id)
            end
        end
        @assign_rule.update(status: 1)
        redirect_to order_dispatches_path(order_filter: 'ready')
        flash[:notice] = 'Mail Service Rule Assigned!'
    else
        redirect_to order_dispatches_path(order_filter: 'ready')
        flash[:alert] = @assign_rule.errors.full_messages
    end
  end

  def update
    @assign_rule = AssignRule.find(params[:id])
    @assign_rule.update(assign_rule_params)
    redirect_to order_dispatches_path(order_filter: 'ready')
    flash[:notice] = 'Mail Service Rule Updated!'
  end

  private

  def assign_rule_params
    params.require(:assign_rule).permit(:mail_service_rule_id, :save_later, :status, :product_ids, :initial_weight,
                                        mail_service_labels_attributes: %i[id length width height weight product_ids courier_id _destroy]
      )
  end
end