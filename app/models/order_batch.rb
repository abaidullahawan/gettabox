# frozen_string_literal: true

# personal detail have all relvent infotmation about user
class OrderBatch < ApplicationRecord
  enum print_packing_list: {
    orders: 'Orders',
    products: 'Products'
  }, _prefix: true
  enum pick_preset: {
    original: 'Orginal',
    all_pick_operations: 'All Pick Operations',
    all_pack_operations: 'All Pack Operations',
    batch: 'Batch',
    all: 'All',
    all_pick_and_batch: 'All Pick + Batch',
    all_pack_and_batch: 'All Pack + Batch'
  }, _prefix: true

  enum options: {
    none: 'None',
    all: 'All',
    empty: 'Empty',
    filled: 'Filled',
    prepend: 'Prepend',
    append: 'Append'
  }, _prefix: true
end
