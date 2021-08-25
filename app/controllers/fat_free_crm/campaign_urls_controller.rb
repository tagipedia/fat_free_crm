# frozen_string_literal: true

# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module FatFreeCrm
class CampaignUrlsController < FatFreeCrm::EntitiesController

  # GET /campaign_urls/new
  #----------------------------------------------------------------------------
  def new
    @campaign_url.attributes = {}
    get_campaigns

    if params[:related]
      model, id = params[:related].split('_')
      if related = "FatFreeCrm::#{model.classify}".constantize.my(current_user).find_by_id(id)
        instance_variable_set("@#{model}", related)
      else
        respond_to_related_not_found(model) && return
      end
    end

    respond_with(@campaign_url)
  end

  # GET /campaign_urls/1/edit                                                      AJAX
  #----------------------------------------------------------------------------
  def edit
    get_campaigns

    @previous = CampaignUrl.my(current_user).find_by_id(Regexp.last_match[1]) || Regexp.last_match[1].to_i if params[:previous].to_s =~ /(\d+)\z/

    respond_with(@campaign_url)
  end

  # POST /campaign_urls
  #----------------------------------------------------------------------------
  def create
    get_campaigns

    respond_with(@campaign_url) do |_format|
      if @campaign_url.save_with_params(params.permit!)
        if called_from_index_page?
          @campaign_urls = get_campaign_urls
          get_data_for_sidebar
        else
          get_data_for_sidebar(:campaign)
        end
      end
    end
  end

  # PUT /campaign_urls/1
  #----------------------------------------------------------------------------
  def update
    respond_with(@campaign_url) do |_format|
      if @campaign_url.update_with_params(resource_params)
        update_sidebar
      else
        @campaigns = Campaign.my(current_user).order('name')
      end
    end
  end

  # DELETE /campaign_urls/1
  #----------------------------------------------------------------------------
  def destroy
    @campaign_url.destroy

    respond_with(@campaign_url) do |format|
      format.html { respond_to_destroy(:html) }
      format.js   { respond_to_destroy(:ajax) }
    end
  end

  private

  #----------------------------------------------------------------------------
  alias get_campaign_urls get_list_of_records

  #----------------------------------------------------------------------------
  def get_campaigns
    @campaigns = Campaign.my(current_user).order('name')
  end

  #----------------------------------------------------------------------------
  def respond_to_destroy(method)
    if method == :ajax
      if called_from_index_page? # Called from CampaignUrls index.
        get_data_for_sidebar
        @campaign_urls = get_campaign_urls
        if @campaign_urls.blank?
          # If no CampaignUrl on this page then try the previous one.
          # and reload the whole list even if it's empty.
          @campaign_urls = get_campaign_urls(page: current_page - 1) if current_page > 1
          render(:index) && return
        end
      else # Called from related asset.
        # Reset current page to 1 to make sure it stays valid.
        # Reload CampaignUrl's campaign if any and render destroy.js
        self.current_page = 1
        @campaign = @campaign_url.campaign
      end
    else # :html destroy
      self.current_page = 1
      flash[:notice] = t(:msg_asset_deleted, @campaign_url.url)
      redirect_to campaign_urls_path
    end
  end

  #----------------------------------------------------------------------------
  def get_data_for_sidebar(related = false)
    if related
      instance_variable_set("@#{related}", @campaign_url.send(related)) if called_from_landing_page?(related.to_s.pluralize)
    else
      # TODO support it if we will support index page
    end
  end

  #----------------------------------------------------------------------------
  def update_sidebar
    if called_from_index_page?
      get_data_for_sidebar
    else
      get_data_for_sidebar(:campaign)
    end
  end
end
end
