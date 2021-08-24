class RemoveReferenceFromCategory < ActiveRecord::Migration[6.1]
  def change
    remove_reference :categories, :product, index: true
  end
end
