class News
  include Mongoid::Document

  field :date, type: Date
  field :title, type: String
  field :link, type: String
  field :description, type: String
  field :image_url, type: String

  def formatted_title
    ActionController::Base.helpers.strip_tags(self.title).squish
  end

  def formatted_description
    ActionController::Base.helpers.strip_tags(self.description).squish
  end

  def formatted_date
    self.date.strftime('%d %b %Y')
  end
end
