# frozen_string_literal: true

# AssignRule
class AssignRulesController < ApplicationController
  before_action :customize_rule, only: %i[create]

  def index; end

  def create
    channel_order = ChannelOrder.find(params[:channel_order_id])
    criteria = channel_order.channel_order_items.map { |h| [h[:sku], h[:ordered]] }
    @assign_rule.criteria = criteria
    if @assign_rule.update(assign_rule_params)
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
    @assign_rule.update(status: 'customized') if check_labels(assign_rule_params[:mail_service_labels_attributes]['0']) || assign_rule_params[:mail_service_labels_attributes]['1'].present?
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

  def customize_rule
    assign_rule_labels = assign_rule_params[:mail_service_labels_attributes].to_h
    @assign_rule = AssignRule.new
    return unless assign_rule_labels['1'].nil? || check_labels(assign_rule_labels['0'])

    @assign_rule = AssignRule.new(status: 'customized')
  end

  def check_labels(assign_rule_labels)
    return false if assign_rule_labels['length'] == params[:hidden_length] && assign_rule_labels['width'] == params[:hidden_width] && assign_rule_labels['height'] == params[:hidden_height] && assign_rule_labels['weight'] == params[:hidden_weight]

    true
  end
end
