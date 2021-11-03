module StaticError
  extend ActiveSupport::Concern

  included do
    validate :check_static_errors
  end

  def add_static_error(*args)
    @static_errors = [] if @static_errors.nil?
    @static_errors << args

    true
  end

  def clear_static_error
    @static_errors = nil
  end

  private

  def check_static_errors
    @static_errors&.each do |error|
      errors.add(*error)
    end
  end
end
