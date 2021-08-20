module FatFreeCrm
  class CampaignUrl < ApplicationRecord
    belongs_to :campaign, optional: true

    def save_with_params(params)
      self.campaign = Campaign.find(params[:campaign]) unless params[:campaign].blank?
      self.attributes = params[:campaign_url]
      save
    end

    def update_with_params(attributes)
      self.attributes = attributes
      save
    end

    def full_url
      uri =  URI.parse(url)
      uri.query = [
        uri.query,
        "utm_source=#{utm_source}",
        "utm_medium=#{utm_medium}",
        "utm_campaign=#{utm_campaign}",
        "utm_term=#{utm_term}",
        "utm_content=#{utm_content}"
      ].compact.join('&')
      uri.to_s
    end
  end
end
