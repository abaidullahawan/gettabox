# frozen_string_literal: true

# issue orders fixing job
class IssueOrdersJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    orders = ChannelOrder.where(stage: 'unable_to_find_sku')
    return unless orders.present?

    orders.each do |order|
      order.channel_order_items.each do |item|
        product_id = ChannelProduct.find_by(channel_type: order.channel_type, listing_id: item.line_item_id, item_sku: item.sku)&.id
        item.update(channel_product_id: product_id) if product_id.present?
      end
      extra_update_order_stage(order.channel_order_items.map { |i| i.channel_product&.status }, order)
      order.update(stage: 'issue') if order.channel_order_items.map(&:sku).any? nil
    end
  end

  def extra_update_order_stage(condition, order)
    if condition.any?(nil)
      order.update(stage: 'unable_to_find_sku')
    elsif condition.any?('unmapped')
      order.update(stage: 'unmapped_product_sku')
    else
      order.update(stage: 'ready_to_dispatch')
      allocate_or_unallocate(order.channel_order_items)
      assign_rule(order)
    end
  end

  def allocate_or_unallocate(channel_items)
    channel_items.each do |item|
      product = item.channel_product.product_mapping.product
      if product.present?
        next multipack_product(item, product) unless product.product_type.eql? 'single'

        inventory_balance = product.inventory_balance.to_f - item.ordered
        update_available_stock(item, product, inventory_balance, item.ordered)
      end
    end
  end

  def multipack_product(item, product)
    available = product.multipack_products.map { |m| m.child.available_stock.to_i }
    required = product.multipack_products.map { |m| m.quantity.to_i * item.ordered }
    check = available.zip(required).all? { |a, b| a >= b }
    return unless check

    multipack_allocation(item, product)
  end

  def multipack_allocation(item, product)
    product.multipack_products.each do |multipack|
      quantity = multipack.quantity
      child = multipack.child

      available_stock = child.available_stock.to_f - (item.ordered * quantity)
      update_available_stock(item, child, available_stock, (item.ordered * quantity))
    end
  end

  def update_available_stock(item, product, inventory_balance, ordered)
    unshipped = product.unshipped + ordered if product.unshipped.present?
    product.update(change_log: "API, #{item.channel_product.item_sku}, #{item.channel_order.order_id}, Order Paid,
        #{item.channel_product.listing_id}, #{unshipped}, #{product.inventory_balance} ", unshipped: unshipped, unshipped_orders: product.unshipped_orders.to_i + 1,
        inventory_balance: inventory_balance)
    if product.inventory_balance >= ordered
      product.update(allocated: product.allocated.to_i + ordered, allocated_orders: product.allocated_orders.to_i + 1)
      item.update(allocated: true)
    else
      item.update(allocated: false)
    end
  end

  def assign_rule(order)
    unless order.assign_rule&.save_later

      no_rule = false
      total_weight = 0
      total_postage = order.postage.to_f
      rule_bonus_score = {}
      carrier_type_multi = []
      type = false
      equal = false
      carrier_type = nil
      order.channel_order_items.each do |item|
        if item.channel_product&.product_mapping.present?
          if item.channel_product&.product_mapping&.product&.product_type == 'multiple'
            item.channel_product&.product_mapping&.product&.multipack_products&.each do |multipack_product|
              carrier_type_multi.push(multipack_product.child&.courier_type)
              total_weight += multipack_product.child.weight.to_i * multipack_product.quantity.to_i * item.ordered.to_i
            end
          else
            carrier_type = item.channel_product&.product_mapping&.product&.courier_type
            total_weight = item.channel_product&.product_mapping&.product&.weight.to_i * item.ordered.to_i
          end
        end
      end
      carrier_type_multi.map {|v| v.downcase! if v.is_a? String}
      if carrier_type.blank?
        carrier_type = (carrier_type_multi&.include? 'hermes') ? 'hermes' : (carrier_type_multi&.include? 'yodal') ? 'yodal' : carrier_type_multi&.last
      end
      MailServiceRule.all.each do |mail_rule|
        min_weight = 0
        max_weight = 0
        min_postage = 0
        max_postage = 0
        mail_rule.rules.each do |rule|
          if rule.rule_field == 'weight_in_gm'
            operator = rule.rule_operator
            case operator
            when 'greater_then'
              min_weight = rule.rule_value.to_i + 1
            when 'greater_then_equal'
              min_weight = rule.rule_value.to_i
            when 'less_then_equal'
              max_weight = rule.rule_value.to_i
            when 'less_then'
              max_weight = rule.rule_value.to_i - 1
            end
          elsif rule.rule_field == 'carrier_type'
            operator = rule.rule_operator
            type = (operator == 'equals' && rule&.rule_value&.downcase == carrier_type&.downcase) ? true : false
          elsif rule.rule_field == 'postage'
            operator = rule.rule_operator
            case operator
            when 'greater_then'
              min_postage = rule.rule_value.to_f + 0.1
            when 'greater_then_equal'
              min_postage = rule.rule_value.to_f
            when 'less_then_equal'
              max_postage = rule.rule_value.to_f
            when 'less_then'
              max_postage = rule.rule_value.to_f - 0.1
            when 'equals'
              equal  = true
            end
            if max_postage == 0 && min_postage == 0
              type = rule.rule_value.to_f == total_postage.to_f ? true : false
            else
              type = true if total_postage.to_f <= max_postage && total_postage.to_f >= min_postage || rule.rule_value.to_f == total_postage
            end
          end
        end
        if type == false
          if max_weight == 0 && min_weight == 0
            type = false
          else
            type = true if total_weight.to_i <= max_weight && total_weight.to_i >= min_weight || min_weight > 0 && max_weight == 0 && mail_rule.rules.count.to_i < 2 && total_weight.to_i >= min_weight
          end
        end
        rule_bonus_score[mail_rule.bonus_score.to_i] = mail_rule.id if type
        no_rule = true if type
        type = false
        if no_rule
          if rule_bonus_score.max&.last.present?
            mail_rule_id = rule_bonus_score.max&.last
            assign_rule = AssignRule.create(mail_service_rule_id: mail_rule_id)
            order&.channel_order_items&.each do |item|
              if item.channel_product&.product_mapping&.product&.product_type == 'multiple'
                quantity = item&.ordered
                length = 0
                weight = 0
                width = 0
                height = 0
                item.channel_product&.product_mapping&.product&.multipack_products.each do |multipack_product|
                  length += multipack_product.child.length.to_f * quantity * multipack_product.quantity
                  weight += multipack_product.child.weight.to_f * quantity * multipack_product.quantity
                  width += multipack_product.child.width.to_f
                  height += multipack_product.child.height.to_f
                end
                @service_label = MailServiceLabel.create(height: height, weight: weight,
                                                        length: length, width: width, assign_rule_id: assign_rule.id)
              else
                quantity = item&.ordered
                length = item&.channel_product&.product_mapping&.product&.length.to_f * quantity
                weight = item&.channel_product&.product_mapping&.product&.weight.to_f * quantity
                width = item&.channel_product&.product_mapping&.product&.width.to_f
                height = item&.channel_product&.product_mapping&.product&.height.to_f
                @service_label = MailServiceLabel.create(height: height, weight: weight,
                                                        length: length, width: width, assign_rule_id: assign_rule.id)
              end
            end
            order.update(total_weight: total_weight) if order.total_weight.nil?
            order.update(assign_rule_id: assign_rule.id)
          end
        else
          order.update(total_weight: total_weight) if order.total_weight.nil?
          order.update(assign_rule_id: nil)
        end
      end
    end
  end
end
