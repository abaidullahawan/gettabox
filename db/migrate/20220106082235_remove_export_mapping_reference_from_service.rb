class RemoveExportMappingReferenceFromService < ActiveRecord::Migration[6.1]
  def change
    remove_reference :services, :export_mapping
  end
end
