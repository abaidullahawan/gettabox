# frozen_string_literal: true

json.array! @import_mappings, partial: 'import_mappings/import_mapping', as: :import_mapping
