class CreateFatFreeCrmCampaignUrls < ActiveRecord::Migration[6.0]
  def change
    create_table :fat_free_crm_campaign_urls do |t|
      t.references :campaign
      t.string :url
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_campaign
      t.string :utm_term
      t.string :utm_content
      t.timestamps
    end
  end
end
