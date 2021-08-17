module FatFreeCrm
  class EmailDesign < ApplicationRecord
    attribute :source_info, :jsonb, default: {}
    enum source_info_type: {singlesend: "singlesend", automation: "automation"}

    belongs_to :campaign, optional: true
  end
end
