class AddUniqueToEmailInLeads < ActiveRecord::Migration[6.0]
  def change
    add_index :fat_free_crm_leads, :email, :unique => true
  end
end
