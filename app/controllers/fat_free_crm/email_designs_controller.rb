# frozen_string_literal: true

# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module FatFreeCrm
class EmailDesignsController < FatFreeCrm::EntitiesController

  # GET /email_designs/new
  #----------------------------------------------------------------------------
  def new
    @email_design.attributes = {}
    get_campaigns

    if params[:related]
      model, id = params[:related].split('_')
      if related = "FatFreeCrm::#{model.classify}".constantize.my(current_fat_free_crm_user).find_by_id(id)
        instance_variable_set("@#{model}", related)
      else
        respond_to_related_not_found(model) && return
      end
    end

    respond_with(@email_design)
  end

  # GET /email_designs/1/edit                                                      AJAX
  #----------------------------------------------------------------------------
  def edit
    get_campaigns

    @previous = EmailDesign.my(current_fat_free_crm_user).find_by_id(Regexp.last_match[1]) || Regexp.last_match[1].to_i if params[:previous].to_s =~ /(\d+)\z/

    respond_with(@email_design)
  end

  # POST /email_designs
  #----------------------------------------------------------------------------
  def create
    get_campaigns

    respond_with(@email_design) do |_format|
      if @email_design.save_with_params(params.permit!)
        if called_from_index_page?
          @email_designs = get_email_designs
          get_data_for_sidebar
        else
          get_data_for_sidebar(:campaign)
        end
      end
    end
  end

  # PUT /email_designs/1
  #----------------------------------------------------------------------------
  def update
    respond_with(@email_design) do |_format|
      if @email_design.update_with_params(resource_params)
        update_sidebar
      else
        @campaigns = Campaign.my(current_fat_free_crm_user).order('name')
      end
    end
  end

  # DELETE /email_designs/1
  #----------------------------------------------------------------------------
  def destroy
    @email_design.destroy

    respond_with(@email_design) do |format|
      format.html { respond_to_destroy(:html) }
      format.js   { respond_to_destroy(:ajax) }
    end
  end

  private

  #----------------------------------------------------------------------------
  alias get_email_designs get_list_of_records

  #----------------------------------------------------------------------------
  def get_campaigns
    @campaigns = Campaign.my(current_fat_free_crm_user).order('name')
  end

  #----------------------------------------------------------------------------
  def respond_to_destroy(method)
    if method == :ajax
      if called_from_index_page? # Called from EmailDesigns index.
        get_data_for_sidebar
        @email_designs = get_email_designs
        if @email_designs.blank?
          # If no EmailDesign on this page then try the previous one.
          # and reload the whole list even if it's empty.
          @email_designs = get_email_designs(page: current_page - 1) if current_page > 1
          render(:index) && return
        end
      else # Called from related asset.
        # Reset current page to 1 to make sure it stays valid.
        # Reload EmailDesign's campaign if any and render destroy.js
        self.current_page = 1
        @campaign = @email_design.campaign
      end
    else # :html destroy
      self.current_page = 1
      flash[:notice] = t(:msg_asset_deleted, @email_design.url)
      redirect_to email_designs_path
    end
  end

  #----------------------------------------------------------------------------
  def get_data_for_sidebar(related = false)
    if related
      instance_variable_set("@#{related}", @email_design.send(related)) if called_from_landing_page?(related.to_s.pluralize)
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
