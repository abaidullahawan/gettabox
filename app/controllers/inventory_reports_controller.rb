# frozen_string_literal: true

# Inventory Reports
class InventoryReportsController < ApplicationController

  def index
    @inventory_products = Product.last(20)
  end
end
