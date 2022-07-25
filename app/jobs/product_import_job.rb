# frozen_string_literal: true

#Product Import Job
class ProductImportJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    filename = _args.last[:filename] || _args.last['filename']
    current_user = _args.last[:current_user] || _args.last['current_user']
    mapping_type = _args.last[:mapping_type] || _args.last['mapping_type']
    csv_text = File.read(Rails.root.join('tmp', filename)).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
    if mapping_type.present?
      convert = ImportMapping.where(sub_type: mapping_type).last.mapping_data.invert
      csv = CSV.parse(csv_text, headers: true, skip_blanks: true, header_converters: lambda { |name| convert[name] })
    else
      csv = CSV.parse(csv_text, headers: true)
    end
    return unless csv.present?

    csv.delete('id')
    csv.delete('created_at')
    csv.delete('updated_at')
    csv_create_records(csv, current_user)
    File.delete(Rails.root.join('tmp', filename))
  end

  def csv_create_records(csv, current_user)
    csv.each do |row|
      hash = row.to_hash
      hash.delete(nil)
      hash['product_type'] = hash['product_type']&.downcase
      hash['vat'] = hash['vat'].to_i
      hash['total_stock'] = hash['total_stock'].to_i
      product = Product.with_deleted.find_or_initialize_by(sku: hash['sku'])
      next product.update(hash) if hash['category_id'].to_i.positive?

      hash['category_id'] = Category.where('title ILIKE ?', hash['category_id'])
                                    .first_or_create(title: hash['category_id']).id
      hash['product_location_id'] = ProductLocation.find_or_create_by(location: hash['product_location_id']).id
      if hash['total_stock'].present? && product.total_stock.present?
        difference = hash['total_stock'].to_i - product.total_stock.to_i
        stock = product.manual_edit_stock.to_i
        stock += difference
        product.update(manual_edit_stock: stock, change_log: "Manual Edit, Spreadsheet, #{stock}, Manual Edit, , #{(hash['total_stock'].to_i - product.unshipped.to_i)}, #{current_user}")
      end
      product.update!(hash)
      Barcode.find_or_create_by(product_id: product.id, title: hash['barcode'])  if hash['barcode'].present?
    end
  end
end
