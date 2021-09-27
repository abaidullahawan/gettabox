class ExtraFieldName < ApplicationRecord
    belongs_to :fieldnameable, polymorphic: true
end
