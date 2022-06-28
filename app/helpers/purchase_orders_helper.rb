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

  def pallet_quantity(product_id, quantity, quantity_type)
    product = Product.find_by(id: product_id)
    return 0 if product.pallet_quantity.nil?

    return quantity if quantity_type.eql? 'pallet_quantity'

    return (quantity / product.pallet_quantity) if quantity_type.eql? 'pack_quantity'

    return (quantity / product.pack_quantity / product.pallet_quantity) if quantity_type.eql? 'single'
  end

  def pack_quantity(product_id, quantity, quantity_type)
    product = Product.find_by(id: product_id)
    return 0 if product.pack_quantity.nil?

    return 0 if quantity_type.eql? 'pallet_quantity'

    return (quantity % product.pallet_quantity ) if quantity_type.eql? 'pack_quantity'

    return (quantity / product.pack_quantity) if (quantity_type.eql? 'single') && product.pallet_quantity.nil?

    return (quantity % product.pallet_quantity / product.pack_quantity) if quantity_type.eql? 'single'
  end

  def single_quantity(product_id, quantity, quantity_type)
    product = Product.find_by(id: product_id)
    return quantity if product.pack_quantity.nil? && product.pallet_quantity.nil?

    return 0 if quantity_type.eql? 'pallet_quantity'

    return 0 if quantity_type.eql? 'pack_quantity'

    return (quantity % product.pack_quantity) if (quantity_type.eql? 'single') && product.pallet_quantity.nil?

    return (quantity % product.pallet_quantity % product.pack_quantity) if quantity_type.eql? 'single'
  end
end
