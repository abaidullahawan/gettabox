class CreateEmailTemplates < ActiveRecord::Migration[6.1]
  def change
    create_table :email_templates do |t|
      t.string :template_type
      t.string :template_name
      t.string :subject
      t.string :body

      t.timestamps
    end
  end
end
