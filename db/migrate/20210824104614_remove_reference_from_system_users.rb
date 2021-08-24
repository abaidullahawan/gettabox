class RemoveReferenceFromSystemUsers < ActiveRecord::Migration[6.1]
  def change
    remove_reference :system_users, :product, index: true
  end
end
