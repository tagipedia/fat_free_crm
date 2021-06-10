# frozen_string_literal: true

class ConvertRadioToRadioButtons < ActiveRecord::Migration[4.2]
  module SingletonMethods
    def field_groups
      FatFreeCrm::Field.table_name = 'fields'
      FatFreeCrm::FieldGroup.table_name = 'field_groups'
      if ActiveRecord::Base.connection.data_source_exists? 'field_groups'
        FatFreeCrm::FieldGroup.where(klass_name: name).order(:position)
      else
        []
      end
    end
  end
  def up
    FatFreeCrm::Field.table_name = 'fields'
    FatFreeCrm::FieldGroup.table_name = 'field_groups'
    # UPDATE "fields" SET "as" = 'radio_buttons' WHERE "fields"."as" = $1  [["as", "radio"]]
    FatFreeCrm::Field.where(as: 'radio').update_all(as: 'radio_buttons')
  end

  def down
    FatFreeCrm::Field.where(as: 'radio_buttons').update_all(as: 'radio')
  end
end
