# frozen_string_literal: true

# AssignRule
class AssignRulesController < ApplicationController

  def index; end
  def create
    channel_order = ChannelOrder.find(params[:channel_order_id])
    criteria = channel_order.channel_order_items.map { |h| [h[:sku], h[:ordered]] }

    @assign_rule = AssignRule.new(assign_rule_params)
    @assign_rule.criteria = criteria
    if @assign_rule.save
      if @assign_rule.save_later
        ChannelOrder.where.not(order_status: %w[FULFILLED Shipped]).each do |order|
          check_criteria = order.channel_order_items.map { |h| [h[:sku], h[:ordered]] }
          order.update(assign_rule_id: @assign_rule.id) if check_criteria == criteria && order.assign_rule.nil?
        end
      else
        channel_order.update(assign_rule_id: @assign_rule.id)
      end
      redirect_to order_dispatches_path(order_filter: 'ready')
      flash[:notice] = 'Mail Service Rule Assigned!'
    else
      redirect_to order_dispatches_path(order_filter: 'ready')
      flash[:alert] = @assign_rule.errors.full_messages
    end
  end

  def update
    @assign_rule = AssignRule.find(params[:id])
    channel_order = ChannelOrder.find(params[:update_channel_order_id])
    criteria = channel_order.channel_order_items.map { |h| [h[:sku], h[:ordered]] }

    if @assign_rule.save_later
      hash = assign_rule_params.to_h
      hash['mail_service_labels_attributes']['0']['id'] = nil
      @assign_rule = AssignRule.new(hash)
    end
    @assign_rule.new_record? ? @assign_rule.save : @assign_rule.update(assign_rule_params)
    @assign_rule.update(criteria: criteria)
    channel_order.update(assign_rule_id: @assign_rule.id)
    redirect_to order_dispatches_path(order_filter: 'ready')
    flash[:notice] = 'Mail Service Rule Updated!'
  end

  private

  def assign_rule_params
    params.require(:assign_rule)
          .permit(:mail_service_rule_id, :save_later, :status, :product_ids, :initial_weight,
                  mail_service_labels_attributes: %i[id length width height weight product_ids courier_id _destroy])
  end
end
