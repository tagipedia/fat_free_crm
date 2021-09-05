module FatFreeCrm
  class LeadAlias < ActiveRecord::Base
    belongs_to :lead, :dependent => :destroy

    validates_presence_of :lead_id, :destroyed_lead_id

    # Takes a list of ids, returns a list of ids that have been merged
    # E.g. If ids = [9876, 1111] returns {"9876"=>"1490"}
    def self.ids_with_alias(ids)
      h = {}
      return {} if ids.nil?
      where(:destroyed_lead_id => ids).each do |ca|
        h[ca.destroyed_lead_id.to_s] = ca.lead_id.to_s
      end
      h
    end
  end
end
