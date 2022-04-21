# frozen_string_literal: true

# Dispatch Reports
class DispatchReportsController < ApplicationController
  include Reports

  def index
    @sale_channels = SystemUser.sales_channels.deep_dup
    @sale_channels['all_channels'] = 'All Channels'
    @sale_channels = @sale_channels.sort.to_h
    @date = date_from_to
    case params[:type]
    when 'Product'
      @channel_products_export, @channel_products = channel_order(@date)
    when 'Order'
      @channel_orders_export, @channel_orders = channel_order(@date)
    when 'Shipment'
      @channel_shipment_export, @channel_shipments = channel_order(@date)
    end

    export_reports_products if params[:commit] == 'Export Button' && params[:type] == 'Product'
    export_reports_orders if params[:commit] == 'Export Button' && params[:type] == 'Order'
    export_reports_shipments if params[:commit] == 'Export Button' && params[:type] == 'Shipment'
  end

  private

  def export_reports_products
    csv_data = CSV.generate(headers: true) do |csv|
      csv << csv_headers
      @channel_products_export.each do |order|
        order.channel_order_items.each do |product|
          if product.channel_product&.product_mapping&.product&.product_type_single?
            tracking_no = []
            service = []
            carrier = []
            order.trackings.each do |tracking|
              tracking_no.push(tracking.tracking_no)
              service.push(tracking.service)
              carrier.push(tracking.carrier)
            end
            csv << [
              order.channel_type, order.buyer_name,
              order.versions.last.whodunnit.present? ? User.find_by(id: order.versions.last.whodunnit)&.personal_detail&.full_name : 'No User',
              order.versions.last.changeset['updated_at'].last.strftime('%m/%d/%Y %I:%M %p'), product.channel_order_id,
              order.order_id, order.created_at.strftime('%m/%d/%Y'), product.channel_product&.product_mapping&.product&.title,
              product.channel_product&.product_mapping&.product&.sku, product&.ordered.to_i, order.total_weight.to_f,
              order.total_amount, product.channel_product&.product_mapping&.product&.cost_price.to_f,
              order.postage.to_f, carrier.join(', '), service.join(', '), tracking_no.join(', '),
              order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
            ]
          else
            total_cost_price = 0
            product.channel_product&.product_mapping&.product&.multipack_products&.each do |record|
              total_cost_price += record.child&.cost_price.to_f * record.quantity * product.ordered.to_i
            end
            tracking_no = []
            service = []
            carrier = []
            order.trackings.each do |tracking|
              tracking_no.push(tracking.tracking_no)
              service.push(tracking.service)
              carrier.push(tracking.carrier)
            end
            product.channel_product&.product_mapping&.product&.multipack_products&.each do |record|
              cost_price = record.child&.cost_price.to_f * record.quantity * product.ordered.to_i
              distributed_cost_price = (order.total_amount / total_cost_price) * cost_price
              csv << [
                order.channel_type, order.buyer_name,
                order.versions.last.whodunnit.present? ? User.find_by(id: order.versions.last.whodunnit)&.personal_detail&.full_name : 'No User',
                order.versions.last.changeset['updated_at'].last.strftime('%m/%d/%Y %I:%M %p'), product.channel_order_id,
                order.order_id, order.created_at.strftime('%m/%d/%Y'), record&.child&.title, record&.child&.sku,
                record.quantity * product.ordered.to_i, order.total_weight.to_f, distributed_cost_price.round(2),
                record.child&.cost_price.to_f * record.quantity * product.ordered.to_i, order.postage.to_f,
                carrier.join(', '), service.join(', '), tracking_no.join(', '),
                order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
              ]
            end
          end
        end
      end
    end
    send_data csv_data, filename: "dispatch-reports-for-products-#{Date.today}.csv", disposition: :attachment
  end

  def export_reports_orders
    csv_data = CSV.generate(headers: true) do |csv|
      csv << csv_headers
      @channel_orders_export.each do |order|
        order.channel_order_items.each do |product|
          if product.channel_product&.product_mapping&.product&.product_type_single?
            tracking_no = []
            service = []
            carrier = []
            order.trackings.each do |tracking|
              tracking_no.push(tracking.tracking_no)
              service.push(tracking.service)
              carrier.push(tracking.carrier)
            end
            courier = product.channel_product&.product_mapping&.product&.courier_type
            csv << [
              order.channel_type, order.buyer_name,
              order.versions.last.whodunnit.present? ? User.find_by(id: order.versions.last.whodunnit)&.personal_detail&.full_name : 'No User',
              order.versions.last.changeset['updated_at'].last.strftime('%m/%d/%Y %I:%M %p'), product.channel_order_id,
              order.order_id, order.created_at.strftime('%m/%d/%Y'), product.channel_product&.product_mapping&.product&.title,
              product.channel_product&.product_mapping&.product&.sku, product&.ordered.to_i, order.total_weight.to_f,
              order.total_amount, product.channel_product&.product_mapping&.product&.cost_price.to_f, order.postage.to_f,
              carrier.join(', '), service.join(', '), tracking_no.join(', '),
              order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
            ]
          else
            title = []
            sku = []
            quantity = []
            total_cost_price = 0
            product.channel_product&.product_mapping&.product&.multipack_products&.each do |record|
              title.push(record&.child&.title)
              sku.push(record&.child&.sku)
              qty = record.quantity * product.ordered.to_i
              quantity.push(qty)
              cost_price = record.child&.cost_price.to_f
              total_cost_price += qty * cost_price
            end
            tracking_no = []
            service = []
            carrier = []
            order.trackings.each do |tracking|
              tracking_no.push(tracking.tracking_no)
              service.push(tracking.service)
              carrier.push(tracking.carrier)
            end
            product.channel_product&.product_mapping&.product&.multipack_products&.each do |record|
              courier = record&.child&.courier_type
              csv << [
                order.channel_type, order.buyer_name,
                order.versions.last.whodunnit.present? ? User.find_by(id: order.versions.last.whodunnit)&.personal_detail&.full_name : 'No User',
                order.versions.last.changeset['updated_at'].last.strftime('%m/%d/%Y %I:%M %p'), product.channel_order_id,
                order.order_id, order.created_at.strftime('%m/%d/%Y'), title.join(', '), sku.join(', '),
                quantity.join(', '), order.total_weight.to_f, order.total_amount,
                total_cost_price, order.postage.to_f, carrier.join(', '), service.join(', '), tracking_no.join(', '),
                order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
              ]
            end
          end
        end
      end
    end
    send_data csv_data, filename: "dispatch-reports-for-orders-#{Date.today}.csv", disposition: :attachment
  end

  def export_reports_shipments
    csv_data = CSV.generate(headers: true) do |csv|
      csv << csv_headers
      @channel_orders_export&.each do |order|
        order.channel_order_items&.each do |product|
          if product.channel_product&.product_mapping&.product&.product_type_single?
            courier = product.channel_product&.product_mapping&.product&.courier_type
            order.trackings.each do |tracking|
              csv << [
                order.channel_type, order.buyer_name,
                order.versions.last.whodunnit.present? ? User.find_by(id: order.versions.last.whodunnit)&.personal_detail&.full_name : 'No User',
                order.versions.last.changeset['updated_at'].last.strftime('%m/%d/%Y %I:%M %p'), product.channel_order_id,
                order.order_id, order.created_at.strftime('%m/%d/%Y'), product.channel_product&.product_mapping&.product&.title,
                product.channel_product&.product_mapping&.product&.sku, product&.ordered.to_i, order.total_weight.to_f,
                order.total_amount, product.channel_product&.product_mapping&.product&.cost_price.to_f, order.postage.to_f,
                tracking.carrier, tracking.service, tracking.tracking_no,
                order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
              ]
            end
          else
            total_cost_price = 0
            product.channel_product&.product_mapping&.product&.multipack_products&.each do |record|
              qty = record.quantity * product.ordered.to_i
              cost_price = record.child&.cost_price.to_f
              total_cost_price += qty * cost_price
            end
            product.channel_product&.product_mapping&.product&.multipack_products&.each do |record|
              order.trackings.each do |tracking|
                cost_price = record.child&.cost_price.to_f * record.quantity * product.ordered.to_i
                distributed_cost_price = (order.total_amount / total_cost_price) * cost_price
                courier = record&.child&.courier_type
                csv << [
                  order.channel_type, order.buyer_name,
                  order.versions.last.whodunnit.present? ? User.find_by(id: order.versions.last.whodunnit)&.personal_detail&.full_name : 'No User',
                  order.versions.last.changeset['updated_at'].last.strftime('%m/%d/%Y %I:%M %p'), product.channel_order_id,
                  order.order_id, order.created_at.strftime('%m/%d/%Y'), record&.child&.title, record&.child&.sku,
                  record.quantity * product.ordered.to_i, order.total_weight.to_f, distributed_cost_price.round(2),
                  record.child&.cost_price.to_f * record.quantity * product.ordered.to_i, order.postage.to_f,
                  tracking.carrier, tracking.service, tracking.tracking_no,
                  order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
                ]
              end
            end
          end
        end
      end
    end
    send_data csv_data, filename: "dispatch-reports-for-shipments-#{Date.today}.csv", disposition: :attachment
  end

  def csv_headers
    ['Sales Channel', 'Customer', 'Dispatch User', 'Dispatch Date', 'Order ID', 'Channel Order ID',
     'Order Date(order paid)', 'Product', 'SKU', 'Quantity', 'Total Weight', 'Sale Price (GBP) Net',
     'Cost Price', 'Postage', 'Courier', 'Service', 'Tracking Number', 'Email']
  end
end
