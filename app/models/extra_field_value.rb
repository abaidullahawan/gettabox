class ExtraFieldValue < ApplicationRecord
    belongs_to :fieldvalueable, polymorphic: true
end
