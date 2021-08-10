class JsonbType < ActiveModel::Type::Value
  include ActiveModel::Type::Helpers::Mutable

  def type
    :jsonb
  end

  def deserialize(value)
    if value.is_a?(::String)
      begin
        value = Oj.load(value) rescue nil
      end while value.is_a?(::String)
    end
    value
  end

  def serialize(value)
    if value.nil?
      nil
    else
      if value.is_a? String
        value
      else
        Oj.dump(value)
      end
    end
  end

  def accessor
    ActiveRecord::Store::StringKeyedHashAccessor
  end
end
