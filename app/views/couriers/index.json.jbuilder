# frozen_string_literal: true

json.array! @couriers, partial: 'couriers/courier', as: :courier
