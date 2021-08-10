module FatFreeCrm
  class EmailDesign < ApplicationRecord
    attribute :source_info, :jsonb, default: {}
    enum source_info_type: {singlesend: "singlesend", automation: "automation"}

    has_and_belongs_to_many :campaigns
  end
end
