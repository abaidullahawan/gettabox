# frozen_string_literal: true

module PurchaseOrdersHelper # :nodoc:
  def product_quantities(product_id)
    product = Product.find_by(id: product_id)
    types = {'single' => 1}
    return types unless product.present?

    types['pack_quantity'] = product.pack_quantity unless product.pack_quantity.nil?
    types['pallet_quantity'] = product.pack_quantity * product.pallet_quantity unless product.pallet_quantity.nil?
    types
  end

  # def pallet_quantity(product_id, quantity, quantity_type)
  #   product = Product.find_by(id: product_id)
  #   return 0 if product.pallet_quantity.nil?

  #   return quantity if quantity_type.eql? 'pallet_quantity'

  #   return (quantity / product.pallet_quantity) if quantity_type.eql? 'pack_quantity'

  #   return (quantity / product.pack_quantity / product.pallet_quantity) if quantity_type.eql? 'single'
  # end

  def pack_quantity(product_id, quantity, quantity_type, index)
    product = Product.find_by(id: product_id)
    return 0 if product.pack_quantity.nil?

    return (quantity * product.pallet_quantity) if quantity_type.eql? 'pallet_quantity'

    return quantity if quantity_type.eql? 'pack_quantity'

    return (quantity / product.pack_quantity) if (quantity_type.eql? 'single') && (index.eql? 1)

    return ('1 pack of ' + (quantity % product.pack_quantity).to_s ) if (quantity_type.eql? 'single') && (index.eql? 2)
  end

  def single_quantity(product_id, quantity, quantity_type, index)
    product = Product.find_by(id: product_id)
    return quantity if product.pack_quantity.nil? && product.pallet_quantity.nil?

    return 0 if quantity_type.eql? 'pallet_quantity'

    return 0 if quantity_type.eql? 'pack_quantity'

    return (quantity / product.pack_quantity * product.pack_quantity) if (quantity_type.eql? 'single') && (index.eql? 1)

    return (quantity % product.pack_quantity) if (quantity_type.eql? 'single') && (index.eql? 2)

    # return (quantity  product.pallet_quantity % product.pack_quantity) if quantity_type.eql? 'single'
  end

  def product_singles(product_id, quantity, quantity_type)
    product = Product.find_by(id: product_id)

    return false if product.pack_quantity.nil? && product.pallet_quantity.nil?

    true
  end

  def purchase_order_details_dup(product_id, quantity, quantity_type)
    product = Product.find_by(id: product_id)

    if quantity_type.eql? 'single'
      (quantity % product.pack_quantity).zero? ? 1 : 2
    else
      1
    end
  end
end
