# frozen_string_literal: true

# personal detail have all relvent infotmation about user
class OrderBatch < ApplicationRecord
  acts_as_paranoid
  belongs_to :user, optional: true
  has_many :channel_orders
  validates :pick_preset, uniqueness: true, unless: -> { preset_type_batch_name? }
  enum print_packing_list_options: {
    products: 'Products',
    orders: 'Orders'
  }, _prefix: true
  # enum pick_preset: {
  #   original: 'Orginal',
  #   all_pick_operations: 'All Pick Operations',
  #   all_pack_operations: 'All Pack Operations',
  #   batch: 'Batch',
  #   all: 'All',
  #   all_pick_and_batch: 'All Pick + Batch',
  #   all_pack_and_batch: 'All Pack + Batch'
  # }, _prefix: true
  enum preset_type: {
    pick_preset: 1,
    batch_name: 0
  }, _prefix: true

  enum options: {
    none: 'None',
    all: 'All',
    empty: 'Empty',
    filled: 'Filled',
    prepend: 'Prepend',
    append: 'Append'
  }, _prefix: true

  scope :batches_only, -> { where(preset_type: 'batch_name') }

end
