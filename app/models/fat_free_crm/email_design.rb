module FatFreeCrm
  class EmailDesign < ApplicationRecord
    include StaticError

    attribute :source_info, :jsonb, default: {}
    enum source_info_type: {singlesend: "singlesend", automation: "automation"}

    belongs_to :campaign, optional: true

    def save_with_params(params)
      self.campaign = Campaign.find(params[:campaign]) unless params[:campaign].blank?
      sg = SendGrid::API.new(api_key: Rails.application.credentials[:SENDGRID_API_KEY])
      dataObj = {name: params[:source_info][:name]}
      if self.campaign.present?
        dataObj[:categories] = self.campaign.tag_list || []
      end
      if params[:email_design][:source_info_type] == "singlesend"
        dataObj[:email_config] = {
          editor: "design"
        }
        method_name = "singlesends"
      elsif params[:email_design][:source_info_type] == "automation"
        dataObj[:type] = "triggered"
        dataObj[:status] = "draft"
        dataObj[:steps] = [{
          id: nil,
          send_timing: "PT0S",
          messages: [{
            id: nil,
            template_id: "",
            subject: ""
          }]
        }]
        method_name = "automations"
      else
        raise "Unknown source info type: #{params[:email_design][:source_info_type]}"
      end
      data = JSON.parse(dataObj.to_json)
      response = sg.client.marketing.send(method_name).post(request_body: data)
      body = JSON.parse(response.body)
      if response.status_code == '201'
        self.attributes = {
          source_info_type: params[:email_design][:source_info_type],
          source_info_id: body["id"],
          source_info: body.to_json
        }
      else
        body["errors"].each do |error|
          self.add_static_error(:base, "#{error['field']} #{error['message']}")
        end
      end
      save
    end

    def update_with_params(attributes)
      self.attributes = attributes
      # save
    end
  end
end
