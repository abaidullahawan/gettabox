class ExtraFieldName < ApplicationRecord
    validates_uniqueness_of :field_name
end
