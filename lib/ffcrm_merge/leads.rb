module FfcrmMerge
  module Leads

    IGNORED_ATTRIBUTES = %w(updated_at created_at deleted_at id)
    ORDERED_ATTRIBUTES = %w(email)

    # Call this method on the duplicate lead, to merge it
    # into the master lead.
    # All attributes from 'self' are default, unless defined in options.
    def merge_with(master, ignored_attr = [])
      # Just in case a user tries to merge a lead with itself,
      # even though the interface prevents this from happening.
      return false if master == self

      merge_attr = self.merge_attributes
      # ------ Remove ignored attributes from this lead
      ignored_attr.each { |attr| merge_attr.delete(attr) }

      # Perform all actions in an atomic transaction, so that if one part of the process fails,
      # the whole merge can be rolled back.
      FatFreeCrm::Lead.transaction do

        # ------ Merge attributes: ensure only model attributes are updated.
        model_attributes = merge_attr.dup.reject{ |k,v| !master.attributes.keys.include?(k) || v.blank? }
        master.update_attributes(model_attributes)

        # ------ Merge 'belongs_to' and 'has_one' associations
        {'user_id' => 'user', 'campaign_id' => 'campaign', 'assigned_to' => 'assignee', 'contact' => 'contact'}.each do |attr, method|
          unless ignored_attr.include?(attr)
            if self.send(method).present?
              master.send(method + "=", self.send(method))
            end
          end
        end

        # ------ Merge address associations
        master.address_attributes.keys.each do |attr|
          unless ignored_attr.include?(attr)
            if self.send(attr).present?
              master.send(attr + "=", self.send(attr))
            end
          end
        end

        # ------ Merge 'has_many' associations
        self.tasks.each { |t| t.asset = master; t.save! }
        self.emails.each { |e| e.mediator = master; e.save! }
        self.comments.each { |c| c.commentable = master; c.save! }

        # Merge tags
        all_tags = (self.tags + master.tags).uniq
        master.tag_list = all_tags.map(&:name).join(", ")

        # Call the merge_hook - useful if you have custom actions that need to happen during a merge
        master.merge_hook(self)

        if master.save!
          # Update any existing aliases that were pointing to the duplicate record
          FatFreeCrm::LeadAlias.where(lead_id: self.id).each do |ca|
            ca.update_attribute(:lead, master)
          end

          # Create the lead alias and destroy the merged lead.
          if FatFreeCrm::LeadAlias.create(:lead => master,
                                 :destroyed_lead_id => self.id)
            # Must force a reload of the lead, and shake off all migrated assets.
            self.reload
            self.destroy
          end
        end
      end # transaction
    end

    # Defines the list of Lead class attributes we want to merge.
    # in the order we want to specify them
    def merge_attributes
      attrs = self.attributes.dup.reject{ |k,v| ignored_merge_attributes.include?(k) }
      attrs.merge!(address_attributes) # we want addresses to be shown in the UI
      sorted = attrs.sort do |a,b|
        (ordered_merge_attributes.index(a.first) || 1000) <=> (ordered_merge_attributes.index(b.first) || 1000)
      end
      sorted.inject({}) do |h, item|
        h[item.first] = item.second
        h
      end
    end

    # These attributes need to be included on the merge form but ignore in update_attributes
    # and merged later on in the merge script
    def address_attributes
      {'business_address' => self.business_address.try(:id) }
    end

    # Returns a list of attributes in the order they should appear on the merge form
    def ordered_merge_attributes
      ORDERED_ATTRIBUTES
    end

    # Returns a list of attributes that should be ignored in the merge
    # a function so it can be easily overriden
    def ignored_merge_attributes
      IGNORED_ATTRIBUTES
    end

    #
    # Override this if you want to add additional behavior to merge
    # It is called after merge is performed but before it is saved.
    #
    def merge_hook(duplicate)
      # Example code:
      # duplicate.custom_association.each do |ca|
        # ca.lead = self; ca.save!
      # end
    end

  end
end
