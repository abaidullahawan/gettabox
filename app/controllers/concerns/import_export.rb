# frozen_string_literal: true

# import export for feature contents
module ImportExport
  extend ActiveSupport::Concern

  def filter_object_ids
    params[:object_ids].delete('0') if params[:object_ids].present?
  end

  def klass_bulk_method
    name = controller_name.classify
    object_ids = params[:object_ids]
    if object_ids.present?
      object_ids.each do |p|
        name.constantize.find(p.to_i).delete
      end
      flash[:notice] = "#{name.pluralize} archive successfully"
    else
      flash[:alert] = 'Please select something to perform action.'
    end
  end

  def klass_restore
    name = controller_name.classify
    object_ids = params[:object_ids]
    object_id = params[:object_id]
    commit = params[:commit]
    if object_id.present? && klass_single_restore(object_id, name)
      flash[:notice] = "#{name} restore successfully"
    else
      restore_or_delete(commit, object_ids, name)
    end
  end

  def klass_single_restore(object_id, name)
    if object_id.present?
      name.constantize.restore(object_id)
      true
    else
      false
    end
  end

  def restore_or_delete(commit, object_ids, name)
    if commit == 'Delete' && object_ids.present?
      klass_bulk_delete(object_ids, name)
    elsif commit == 'Restore' && object_ids.present?
      klass_bulk_restore(object_ids, name)
    else
      flash[:notice] = 'Please select something to perform action'
    end
  end

  def klass_bulk_restore(object_ids, name)
    object_ids.each do |p|
      klass_single_restore(p.to_i, name)
    end
    flash[:notice] = "#{name.pluralize} restored successfully"
  end

  def klass_bulk_delete(object_ids, name)
    object_ids.each do |id|
      name.constantize.only_deleted.find(id).really_destroy!
    end
    flash[:notice] = "#{name.pluralize} deleted successfully"
  end

  def klass_import
    file = params[:file]
    if file.present? && file.path.split('.').last.to_s.downcase == 'csv'
      csv_text = File.read(file).force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
      convert = ImportMapping.where(table_name: 'Product').last.mapping_data.invert
      csv = CSV.parse(csv_text, headers: true, skip_blanks: true, header_converters: lambda { |name| convert[name] })
      csv_headers_check(csv)
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
  end

  def csv_headers_check(csv)
    is_valid = (csv.headers.compact | controller_name.classify.constantize.column_names).sort==controller_name.classify.constantize.column_names.sort
    return @csv = csv if is_valid

    flash[:alert] = 'File not matched! Please change file'
  end
end
