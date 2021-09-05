class CreateFatFreeCrmLeadAliases < ActiveRecord::Migration[6.0]
  def change
    create_table :fat_free_crm_lead_aliases do |t|
      t.integer :lead_id
      t.integer :destroyed_lead_id

      t.timestamps
    end
  end
end
