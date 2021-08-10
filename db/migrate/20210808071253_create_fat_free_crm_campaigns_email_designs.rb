class CreateFatFreeCrmCampaignsEmailDesigns < ActiveRecord::Migration[6.0]
  def change
    create_table :fat_free_crm_campaigns_email_designs do |t|
      t.belongs_to :campaign, index: { name: 'index_campaigns_email_designs_on_campaign_id' }
      t.belongs_to :email_design, index: { name: 'index_campaigns_email_designs_on_email_design_id' }
    end
  end
end
