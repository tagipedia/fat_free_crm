# frozen_string_literal: true

# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module FatFreeCrm
module CampaignsHelper
  # Sidebar checkbox control for filtering campaigns by status.
  #----------------------------------------------------------------------------
  def campaign_status_checkbox(status, count)
    entity_filter_checkbox(:status, status, count)
  end

  #----------------------------------------------------------------------------
  def performance(actual, target)
    if target.to_i.positive? && actual.to_i.positive?
      if target > actual
        n = 100 - actual * 100 / target
        html = content_tag(:span, "(-#{number_to_percentage(n, precision: 1)})", class: "warn")
      else
        n = actual * 100 / target - 100
        html = content_tag(:span, "(+#{number_to_percentage(n, precision: 1)})", class: "cool")
      end
    end
    html || ""
  end

  # Quick campaign summary for RSS/ATOM feeds.
  #----------------------------------------------------------------------------
  def campaign_summary(campaign)
    status  = render file: "campaigns/_status.html.haml",  locals: { campaign: campaign }
    metrics = render file: "campaigns/_metrics.html.haml", locals: { campaign: campaign }
    "#{t(campaign.status)}, " + [status, metrics].map { |str| strip_tags(str) }.join(' ').delete("\n")
  end

  def promotion_select(options = {})
    options[:selected] = @campaign&.id.to_i
    promotions = ([@promotion.new_record? ? nil : @promotion] + Spree::Promotion.order(:name).limit(25)).compact.uniq
    collection_select :promotion, :id, promotions, :id, :name,
                      { include_blank: true },
                      style: 'width:330px;', class: 'select2',
                      placeholder: t(:select_an_promotion),
                      "data-url": spree.admin_promotion_auto_complete_path(format: 'json')
  end

  def promotion_select_or_create(form, &_block)
    options = {}
    yield options if block_given?
    content_tag(:div, class: 'label') do
      t(:promotion).html_safe +
        content_tag(:span, id: 'promotion_create_title') do
          " (#{t :create_new} #{t :or} <a href='#' onclick='crm.show_select_promotion(); return false;'>#{t :select_existing}</a>):".html_safe
        end +
        content_tag(:span, id: 'promotion_select_title') do
          " (<a href='#' onclick='crm.show_create_promotion(); return false;'>#{t :create_new}</a> #{t :or} #{t :select_existing}):".html_safe
        end +
        content_tag(:span, ':', id: 'promotion_disabled_title')
    end +
      promotion_select(options) +
      form.text_field(:name, style: 'width:324px; display:none;')
  end



end
end
