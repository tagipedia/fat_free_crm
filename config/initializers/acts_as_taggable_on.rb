module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    self.table_name = "fat_free_crm_tags"
  end

  class Tagging < ::ActiveRecord::Base
    self.table_name = ""
  end
end

ActsAsTaggableOn.tags_table = 'fat_free_crm_tags'
ActsAsTaggableOn.taggings_table = 'fat_free_crm_taggings'
