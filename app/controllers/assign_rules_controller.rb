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
        ChannelOrder.where(stage: "ready_to_dispatch").each do |order|
          check_criteria = order.channel_order_items.map { |h| [h[:sku], h[:ordered]] }
          order.update(assign_rule_id: @assign_rule.id) if check_criteria == criteria
          @assign_rule.update(status: 'customized')
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
    @channel_order = ChannelOrder.find(params[:update_channel_order_id])
    criteria = @channel_order.channel_order_items.map { |h| [h[:sku], h[:ordered]] }

    if @assign_rule.save_later
      hash = assign_rule_params.to_h
      hash['mail_service_labels_attributes'].each { |key, value| value["id"] = nil }
      @assign_rule = AssignRule.new(hash)
    end
    return reset_labels if params['commit'].eql? 'Reset labels'
    @assign_rule.new_record? ? @assign_rule.save : @assign_rule.update(assign_rule_params)
    @assign_rule.update(criteria: criteria)

    # @assign_rule.update(status: 'customized') if (params[:status].eql? 'customized') || check_labels(assign_rule_params[:mail_service_labels_attributes]['0']) || assign_rule_params[:mail_service_labels_attributes]['1'].present?
    if @assign_rule.save_later
      ChannelOrder.where(stage: "ready_to_dispatch").each do |order|
        check_criteria = order.channel_order_items.map { |h| [h[:sku], h[:ordered]] }
        order.update(assign_rule_id: @assign_rule.id) if check_criteria == criteria
        @assign_rule.update(status: 'customized')
      end
    end
    @channel_order.update(assign_rule_id: @assign_rule.id)
    flash[:notice] = 'Mail Service Rule Updated!'
    redirect_to request.referrer
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
    return unless assign_rule_labels['1'].present? || check_labels(assign_rule_labels['0'])

    @assign_rule = AssignRule.new(status: 'customized')
  end

  def check_labels(assign_rule_labels)
    return false if assign_rule_labels['length'] == params[:hidden_length] && assign_rule_labels['width'] == params[:hidden_width] && assign_rule_labels['height'] == params[:hidden_height] && assign_rule_labels['weight'] == params[:hidden_weight]

    true
  end

  def reset_labels
    @assign_rule.mail_service_labels.destroy_all
    @length = 0
    @weight = 0
    @height = []
    @width = []
    @channel_order.channel_order_items.each do |product|
      return unless product.channel_product&.product_mapping.present?

      if product.channel_product.product_mapping.product&.product_type_multiple?
        product.channel_product.product_mapping.product&.multipack_products&.each do |record|
          @length += record&.child&.length.to_f * record.quantity.to_f * product.ordered.to_i
          @weight += record&.child&.weight.to_f * record.quantity.to_f * product.ordered.to_i
          @height.push(record&.child&.height.to_f)
          @width.push(record&.child&.width.to_f)
        end
      else
        @length += product.channel_product.product_mapping&.product&.length.to_f * product.ordered.to_i
        @weight += product.channel_product.product_mapping&.product&.weight.to_f * product.ordered.to_i
        @height.push( product.channel_product.product_mapping&.product&.height.to_f)
        @width.push( product.channel_product.product_mapping&.product&.width.to_f)
      end
    end
    @assign_rule.mail_service_labels.build(length: @length, weight: @weight, height: @height.max, width: @width.max).save
    @assign_rule.update(status: nil)
    @channel_order.update(assign_rule_id: @assign_rule.id)
    flash[:notice] = 'Mail Service Labels reset!'
    redirect_to request.referrer
  end
end
