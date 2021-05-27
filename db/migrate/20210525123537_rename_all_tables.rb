class RenameAllTables < ActiveRecord::Migration[6.0]
  def change
    remove_index :account_contacts, %i[account_id contact_id]
    remove_index :addresses, %i[addressable_id addressable_type]
    remove_index :leads, %i[user_id last_name deleted_at]
    remove_index :taggings, %i[taggable_id taggable_type context]
    remove_index :contact_opportunities, %i[contact_id opportunity_id]
    remove_index :account_opportunities, %i[account_id opportunity_id]

    rename_table :campaigns,             :fat_free_crm_campaigns
    rename_table :users,                 :fat_free_crm_users
    rename_table :groups,                :fat_free_crm_groups
    rename_table :preferences,           :fat_free_crm_preferences
    rename_table :emails,                :fat_free_crm_emails
    rename_table :account_contacts,      :fat_free_crm_account_contacts
    rename_table :settings,              :fat_free_crm_settings
    rename_table :tasks,                 :fat_free_crm_tasks
    rename_table :contacts,              :fat_free_crm_contacts
    rename_table :activities,            :fat_free_crm_activities
    rename_table :addresses,             :fat_free_crm_addresses
    rename_table :leads,                 :fat_free_crm_leads
    rename_table :taggings,              :fat_free_crm_taggings
    rename_table :sessions,              :fat_free_crm_sessions
    rename_table :contact_opportunities, :fat_free_crm_contact_opportunities
    rename_table :opportunities,         :fat_free_crm_opportunities
    rename_table :field_groups,          :fat_free_crm_field_groups
    rename_table :comments,              :fat_free_crm_comments
    rename_table :tags,                  :fat_free_crm_tags
    rename_table :avatars,               :fat_free_crm_avatars
    rename_table :lists,                 :fat_free_crm_lists
    rename_table :permissions,           :fat_free_crm_permissions
    rename_table :accounts,              :fat_free_crm_accounts
    rename_table :account_opportunities, :fat_free_crm_account_opportunities
    rename_table :fields,                :fat_free_crm_fields
    rename_table :groups_users,          :fat_free_crm_groups_users

    # Set also the table names. We need this because in some former migrations they
    # may be set to the old names. This is to avoid problems with further migrations.
    FatFreeCrm::Campaign.table_name           = 'fat_free_crm_campaigns'
    FatFreeCrm::User.table_name               = 'fat_free_crm_users'
    FatFreeCrm::Group.table_name              = 'fat_free_crm_groups'
    FatFreeCrm::Preference.table_name         = 'fat_free_crm_preferences'
    FatFreeCrm::Email.table_name              = 'fat_free_crm_emails'
    FatFreeCrm::AccountContact.table_name     = 'fat_free_crm_account_contacts'
    FatFreeCrm::Setting.table_name            = 'fat_free_crm_settings'
    FatFreeCrm::Task.table_name               = 'fat_free_crm_tasks'
    FatFreeCrm::Contact.table_name            = 'fat_free_crm_contacts'
    FatFreeCrm::Address.table_name            = 'fat_free_crm_addresses'
    FatFreeCrm::Lead.table_name               = 'fat_free_crm_leads'
    FatFreeCrm::Tagging.table_name            = 'fat_free_crm_taggings'
    FatFreeCrm::ContactOpportunity.table_name = 'fat_free_crm_contact_opportunities'
    FatFreeCrm::Opportunity.table_name        = 'fat_free_crm_opportunities'
    FatFreeCrm::FieldGroup.table_name         = 'fat_free_crm_field_groups'
    FatFreeCrm::Comment.table_name            = 'fat_free_crm_comments'
    FatFreeCrm::Tag.table_name                = 'fat_free_crm_tags'
    FatFreeCrm::Avatar.table_name             = 'fat_free_crm_avatars'
    FatFreeCrm::List.table_name               = 'fat_free_crm_lists'
    FatFreeCrm::Permission.table_name         = 'fat_free_crm_permissions'
    FatFreeCrm::Account.table_name            = 'fat_free_crm_accounts'
    FatFreeCrm::AccountOpportunity.table_name = 'fat_free_crm_account_opportunities'
    FatFreeCrm::Field.table_name              = 'fat_free_crm_fields'

    add_index :fat_free_crm_account_contacts, %i[account_id contact_id], name: 'index_ffcrm_account_contacts_on_account_id_and_contact_id'
    add_index :fat_free_crm_addresses, %i[addressable_id addressable_type], name: 'index_ffcrm_addresses_on_addressable_id_and_addressable_type'
    add_index :fat_free_crm_leads, %i[user_id last_name deleted_at], unique: true, name: 'index_ffcrm_leads_on_user_id_and_last_name_and_deleted_at'
    add_index :fat_free_crm_taggings, %i[taggable_id taggable_type context], name: 'index_ffcrm_taggings_on_taggable_id_taggable_type_context'
    add_index :fat_free_crm_contact_opportunities, %i[contact_id opportunity_id], name: 'index_ffcrm_contact_opportunities_on_contact_id_opportunity_id'
    add_index :fat_free_crm_account_opportunities, %i[account_id opportunity_id], name: 'index_ffcrm_account_opportunities_on_account_id_opportunity_id'
  end
end
