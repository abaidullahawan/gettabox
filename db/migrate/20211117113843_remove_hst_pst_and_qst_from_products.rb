class RemoveHstPstAndQstFromProducts < ActiveRecord::Migration[6.1]
  def change
    remove_column :products, :hst
    remove_column :products, :pst
    remove_column :products, :qst
  end
end