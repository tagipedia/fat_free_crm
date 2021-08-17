module FatFreeCrm
  class EmailDesign < ApplicationRecord
    has_and_belongs_to_many :campaigns
    belongs_to :campaign, optional: true
  end
end

class DropFatFreeCrmCampaignsEmailDesigns < ActiveRecord::Migration[6.0]
  def up
    add_reference :fat_free_crm_email_designs, :campaign, index: true
    FatFreeCrm::EmailDesign.all.each do |email_design|
      campaign = email_design.campaigns.first
      if campaign.present?
        email_design.campaign = campaign
        email_design.save!
      end
    end
    drop_table :fat_free_crm_campaigns_email_designs
  end

  def down
    create_table :fat_free_crm_campaigns_email_designs do |t|
      t.belongs_to :campaign, index: { name: 'index_campaigns_email_designs_on_campaign_id' }
      t.belongs_to :email_design, index: { name: 'index_campaigns_email_designs_on_email_design_id' }
    end
    FatFreeCrm::EmailDesign.all.each do |email_design|
      campaign = email_design.campaign
      if campaign.present?
        email_design.campaigns << campaign
        email_design.save!
      end
    end
    remove_reference :fat_free_crm_email_designs, :campaign, index: true
  end
end
