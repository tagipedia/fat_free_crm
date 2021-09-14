# frozen_string_literal: true

# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
# == Schema Information
#
# Table name: leads
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  campaign_id     :integer
#  assigned_to     :integer
#  first_name      :string(64)      default(""), not null
#  last_name       :string(64)      default(""), not null
#  access          :string(8)       default("Public")
#  title           :string(64)
#  company         :string(64)
#  source          :string(32)
#  status          :string(32)
#  referred_by     :string(64)
#  email           :string(64)
#  alt_email       :string(64)
#  phone           :string(32)
#  mobile          :string(32)
#  blog            :string(128)
#  linkedin        :string(128)
#  facebook        :string(128)
#  twitter         :string(128)
#  rating          :integer         default(0), not null
#  do_not_call     :boolean         default(FALSE), not null
#  deleted_at      :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  background_info :string(255)
#  skype           :string(128)
#
require 'roo'
require 'sendgrid-ruby'

module FatFreeCrm
class Lead < ActiveRecord::Base
  include FfcrmMerge::Leads
  belongs_to :user, optional: true # TODO: Is this really optional?
  belongs_to :campaign, optional: true # TODO: Is this really optional?
  belongs_to :assignee, class_name: "User", foreign_key: :assigned_to, optional: true # TODO: Is this really optional?
  has_one :contact, dependent: :nullify # On destroy keep the contact, but nullify its lead_id
  has_many :tasks, as: :asset, dependent: :destroy # , :order => 'created_at DESC'
  has_one :business_address, -> { where "address_type='Business'" }, dependent: :destroy, as: :addressable, class_name: "Address"
  has_many :addresses, dependent: :destroy, as: :addressable, class_name: "Address" # advanced search uses this
  has_many :emails, as: :mediator

  serialize :subscribed_users, Set

  accepts_nested_attributes_for :business_address, allow_destroy: true, reject_if: proc { |attributes| Address.reject_address(attributes) }

  scope :state, lambda { |filters|
    where(['status IN (?)' + (filters.delete('other') ? ' OR status IS NULL' : ''), filters])
  }
  scope :converted,    ->       { where(status: 'converted') }
  scope :for_campaign, ->(id)   { where(campaign_id: id) }
  scope :created_by,   ->(user) { where(user_id: user.id) }
  scope :assigned_to,  ->(user) { where(assigned_to: user.id) }

  scope :text_search, ->(query) { ransack('first_name_or_last_name_or_company_or_email_cont' => query).result }

  uses_user_permissions
  acts_as_commentable
  uses_comment_extensions
  acts_as_taggable_on :tags
  has_paper_trail versions: { class_name: 'FatFreeCrm::Version' }, ignore: [:subscribed_users]
  has_fields
  exportable
  sortable by: ["first_name ASC", "last_name ASC", "company ASC", "rating DESC", "created_at DESC", "updated_at DESC"], default: "created_at DESC"

  has_ransackable_associations %w[contact campaign tasks tags activities emails addresses comments]
  ransack_can_autocomplete

  validates_uniqueness_of :email, if: :email_changed?
  validates_presence_of :first_name, message: :missing_first_name, if: -> { Setting.require_first_names }
  validates_presence_of :last_name,  message: :missing_last_name,  if: -> { Setting.require_last_names  }
  validate :users_for_shared_access
  validates :status, inclusion: { in: proc { Setting.unroll(:lead_status).map { |s| s.last.to_s } } }, allow_blank: true

  after_create :increment_leads_count
  after_destroy :decrement_leads_count

  attr_accessor :skip_register_recipient
  after_save :register_recipient, unless: :skip_register_recipient

  def self.import(file_id)
    file = FileUpload.find(file_id)
    spreadsheet = FatFreeCrm::Lead.open_spreadsheet(file.attachment)
    super_user = FatFreeCrm::User.where(admin: true).first
    leads = []
    (2..spreadsheet.last_row).each_with_index do |i, index|
      if spreadsheet.row(i)[1].present? && spreadsheet.row(i)[2].present? && spreadsheet.row(i)[3].present?
        lead = FatFreeCrm::Lead.find_or_initialize_by(email: spreadsheet.row(i)[3]) do |l|
          l.email = spreadsheet.row(i)[3]
          l.alt_email = spreadsheet.row(i)[3]
          l.user_id = super_user.id
          l.status = 'new'
          l.source = 'self'
        end
        lead.first_name = spreadsheet.row(i)[1] || lead.first_name
        lead.last_name = spreadsheet.row(i)[2] || lead.last_name
        lead.company = spreadsheet.row(i)[7] || lead.company
        lead.title = spreadsheet.row(i)[8] || lead.title
        lead.tag_list = lead.tag_list || []
        lead.tag_list << "contact_excl"
        lead.phone = spreadsheet.row(i)[4] || lead.phone
        lead.mobile = spreadsheet.row(i)[5] || lead.mobile
        if spreadsheet.row(i)[10].present? ||  spreadsheet.row(i)[11].present? ||  spreadsheet.row(i)[14].present? ||  spreadsheet.row(i)[15].present? ||  spreadsheet.row(i)[16].present? || spreadsheet.row(i)[17].present?
          lead.business_address_attributes = {address_type: "Business", street1: spreadsheet.row(i)[10], street2: spreadsheet.row(i)[11], city: spreadsheet.row(i)[14], state: spreadsheet.row(i)[15], zipcode: spreadsheet.row(i)[16],country: spreadsheet.row(i)[17]}
        end
        lead.skip_register_recipient = true
        puts "index", index, spreadsheet.row(i)[1], spreadsheet.row(i)[2], lead.save!
        leads << lead
      end
    end
    FatFreeCrm::Lead.register_recipients(leads)
  end

  def self.open_spreadsheet(file)
    case File.extname(file.identifier)
    when ".csv" then Roo::Csv.new(file.path)
    when ".xls" then Roo::Excel.new(file.path)
    when ".xlsx" then Roo::Excelx.new(file.path)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def self.update_status(json_array)
    status = ""
    rating = 0
    leadStatus = ""
    json_array.each do |json|
      leads = FatFreeCrm::Lead.where(email: json["email"])
      if leads.any?
        leadStatus = leads.first.status
        rating = leads.first.rating
        campaignId = leads.first.campaign_id
        case leads.first.rating
        when 1 then status = "delivered"
        when 3 then status = "open"
        when 4 then status = "click"
        when 5 then status = "buy"
        else status = ""
        end
        if json["event"] == "bounce" || json["event"] == "spamreport"
          status = "rejected"
          rating = 0
          leadStatus = "rejected"
        elsif json["event"] == "click" && status != "buy"
          status = "click"
          rating = 4
          leadStatus = "contacted"
        elsif json["event"] == "open" && status != "click" && status != "buy"
          status = "open"
          rating = 3
          leadStatus = "contacted"
        elsif json["event"] == "delivered" && status != "open" && status != "click" && status != "buy"
          status = "delivered"
          rating = 1
          leadStatus = "contacted"
        end
        if json["singlesend_id"].present? || json["mc_auto_id"].present?
          emailDesign = EmailDesign.find_by(source_info_id: json["singlesend_id"] || json["mc_auto_id"], source_info_type: json["mc_stats"])
          campaignId = emailDesign&.campaign_id || campaignId
        end
        leads.each {|lead| lead.update(rating: rating, status: leadStatus, campaign_id: campaignId)}
      end
    end
  end

  # Default values provided through class methods.
  #----------------------------------------------------------------------------
  def self.per_page
    20
  end

  def self.first_name_position
    "before"
  end

  # Save the lead along with its permissions.
  #----------------------------------------------------------------------------
  def save_with_permissions(params)
    self.campaign = Campaign.find(params[:campaign]) unless params[:campaign].blank?
    if params[:lead][:access] == "Campaign" && campaign # Copy campaign permissions.
      save_with_model_permissions(Campaign.find(campaign_id))
    else
      self.attributes = params[:lead]
      save
    end
  end

  # Update lead attributes taking care of campaign lead counters when necessary.
  #----------------------------------------------------------------------------
  def update_with_lead_counters(attributes)
    if campaign_id == attributes[:campaign_id] # Same campaign (if any).
      self.attributes = attributes
      save
    else                                            # Campaign has been changed -- update lead counters...
      decrement_leads_count                         # ..for the old campaign...
      self.attributes = attributes                  # Assign new campaign.
      lead = save
      increment_leads_count                         # ...and now for the new campaign.
      lead
    end
  end

  # Promote the lead by creating contact and optional opportunity. Upon
  # successful promotion Lead status gets set to :converted.
  #----------------------------------------------------------------------------
  def promote(params)
    account_params = params[:account] || {}
    opportunity_params = params[:opportunity] || {}

    account     = Account.create_or_select_for(self, account_params)
    opportunity = Opportunity.create_for(self, account, opportunity_params)
    contact     = Contact.create_for(self, account, opportunity, params)

    [account, opportunity, contact]
  end

  #----------------------------------------------------------------------------
  def convert
    update_attribute(:status, "converted")
  end

  #----------------------------------------------------------------------------
  def reject
    update_attribute(:status, "rejected")
  end

  # Attach a task to the lead if it hasn't been attached already.
  #----------------------------------------------------------------------------
  def attach!(task)
    tasks << task unless task_ids.include?(task.id)
  end

  # Discard a task from the lead.
  #----------------------------------------------------------------------------
  def discard!(task)
    task.update_attribute(:asset, nil)
  end

  #----------------------------------------------------------------------------
  def full_name(format = nil)
    if format.nil? || format == "before"
      "#{first_name} #{last_name}"
    else
      "#{last_name}, #{first_name}"
    end
  end
  alias name full_name

  def recipient
    {
      first_name: self.first_name || "",
      last_name: self.last_name || "",
      email: self.email || "",
      alternate_emails: self.alt_email.present? ? [self.alt_email] : [],
      phone_number: self.phone || "",
      city: self.business_address.try(:city) || "",
      state_province_region: self.business_address.try(:state) || "",
      postal_code: self.business_address.try(:zipcode) || "",
      country: self.business_address.try(:country) || "",
      address_line_1: self.business_address.try(:street1) || "",
      address_line_2: self.business_address.try(:street2) || "",
      # custom_fields: {
      #   company: self.company,
      #   title: self.title,
      #   tag_list: self.tag_list,
      #   blog: self.blog,
      #   status: self.status,
      #   source: self.source,
      #   mobile_number: self.mobile,
      #   rating: self.rating,
      # },
      custom_fields: {
        e1_T: self.company || "",
        e2_T: self.title || "",
        e3_T: (self.tag_list || []).join(','),
        e4_T: self.blog || "",
        e5_T: self.status || "",
        e6_T: self.source || "",
        e7_T: self.mobile || "",
        e8_N: self.rating || 0,
      }
    }
  end

  private

  #----------------------------------------------------------------------------
  def increment_leads_count
    Campaign.increment_counter(:leads_count, campaign_id) if campaign_id
  end

  #----------------------------------------------------------------------------
  def decrement_leads_count
    Campaign.decrement_counter(:leads_count, campaign_id) if campaign_id
  end

  # Make sure at least one user has been selected if the lead is being shared.
  #----------------------------------------------------------------------------
  def users_for_shared_access
    errors.add(:access, :share_lead) if self[:access] == "Shared" && permissions.none?
  end

  def register_recipient
    FatFreeCrm::Lead.register_recipients([self])
  end
  def self.validate_filter_by(filter_by)
    ['status', 'rating', 'source'].include? filter_by
  end

  def self.status_filter_value
    FatFreeCrm::Setting.unroll(:lead_status).map { |s| s.last.to_s }
  end
  def self.source_filter_value
    FatFreeCrm::Setting.unroll(:lead_source).map { |s| s.last.to_s }
  end
  def self.rating_filter_value
    ['1', '2', '3', '4', '5']
  end
  def self.get_filter_by_value_value(filter_by, filter_by_value)
    FatFreeCrm::Lead.send("#{filter_by}_filter_value").include? filter_by_value
  end

  def self.register_recipients(leads)
    sg = SendGrid::API.new(api_key: Rails.application.credentials[:SENDGRID_API_KEY])
    data = JSON.parse({contacts: leads.map{|lead| lead.recipient}}.to_json)
    response = sg.client.marketing.contacts.put(request_body: data)
  end

  def self.delete_recipient(lead)
    sg = SendGrid::API.new(api_key: Rails.application.credentials[:SENDGRID_API_KEY])
    response = sg.client.marketing.contacts.search.post(request_body: {"query"=>"email = '#{lead.email}'"})
    ids = ActiveSupport::JSON.decode(response.body)['result'].pluck("id")
    response = sg.client..marketing.contacts.delete({query_params: {ids: ids}})
  end

  ActiveSupport.run_load_hooks(:fat_free_crm_lead, self)
end
end
