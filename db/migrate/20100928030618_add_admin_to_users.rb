# frozen_string_literal: true

class AddAdminToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :admin, :boolean, null: false, default: false
    FatFreeCrm::User.table_name = 'users'
    superuser = FatFreeCrm::User.first
    superuser&.update_attribute(:admin, true)
  end

  def self.down
    remove_column :users, :admin
  end
end
