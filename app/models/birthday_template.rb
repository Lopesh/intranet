class BirthdayTemplate
  include Mongoid::Document

  field :current_template_id,       :type => Integer, :default => 0
end
