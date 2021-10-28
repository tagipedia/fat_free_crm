# frozen_string_literal: true

# http://www.atomenabled.org/developers/syndication/
items  = controller.controller_name
item   = items.singularize
assets = controller.instance_variable_get("@#{items}")

atom_feed do |feed|
  feed.title t(:activities)
  feed.updated @activities.max_by(&:created_at).try(:created_at)
  feed.generator "Fat Free CRM v#{FatFreeCrm::VERSION::STRING}"
  feed.author do |author|
    author.name  current_fat_free_crm_user.full_name
    author.email current_fat_free_crm_user.email
  end

  @activities.each do |activity|
    feed.entry(activity, url: '') do |entry|
      entry.title activity_title(activity)

      entry.author do |author|
        author.name activity.user.try(:full_name) || I18n.t('version.anonymous')
      end
    end
  end
end
