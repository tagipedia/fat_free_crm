class CreateFatFreeCrmEmailDesigns < ActiveRecord::Migration[6.0]
  def change
    create_table :fat_free_crm_email_designs do |t|
      t.jsonb :source_info, default: {}
      t.timestamps
    end
  end
end
