class AddSourceInfoIdToEmailDesigns < ActiveRecord::Migration[6.0]
  def change
    add_column :fat_free_crm_email_designs, :source_info_id, :string
  end
end
