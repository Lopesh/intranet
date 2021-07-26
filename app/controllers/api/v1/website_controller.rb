class Api::V1::WebsiteController < ApplicationController

  before_filter :restrict_access
  caches_action :team, cache_path: "website/team"
  caches_action :news, cache_path: "website/news"
  caches_action :portfolio, cache_path: "website/portfolio"
  skip_before_filter :verify_authenticity_token

  def team
    render json: { leaders: User.leaders.as_json(team_fields), members: User.members.as_json(team_fields) }
  end

  def news
    render json: {
      news: News.all.order('date.year': :desc).as_json(methods: [:formatted_date, :formatted_title, :formatted_description])
    }
  end

  def portfolio
    render :json => Project.visible_on_website.sort_by_position.as_json(project_fields)
  end

  def contact_us
    @website_contact = WebsiteContact.new(website_contact_params)
    valid = @website_contact.valid? ? true : false
    if verify_recaptcha(:model => @website_contact, :message => "Oh! It's error with reCAPTCHA!", attribute: 'recaptcha') && valid
      @website_contact.save
      render json: { text: ' ' }, status: :created
    else
      render json: { errors: @website_contact.errors.full_messages.join(",")}, status: :unprocessable_entity
    end
  end

  def career
    @career = Career.new(career_params)
    if @career.save
      render json: { text: ' ' }, status: :created
    else
      render json: { text: ' ' }, status: :unprocessable_entity
    end
  end

  private

  def team_fields
    {
      only: [:email],
      include: {
        public_profile: {
          only: [
            :name, :modal_name, :github_handle, :twitter_handle,
            :facebook_url, :linkedin_url,:blog_url
          ],
          methods: [:name, :image_medium_url, :modal_name]
        },
        employee_detail: {
          only: [:description, :employee_id],
          include: { designation: { only: [:name] }}
        }
      }
    }
  end

  def project_fields
    {only: [:name, :description, :url], methods: [:case_study_url, :tags, :image_url]}
  end

  def restrict_access
    host = URI(request.referer).host if request.referer.present?
    head :unauthorized unless(host.present? && (host.match(/joshsoftware\.com/) || host.match(/josh-website-test/)))
  end

  def website_contact_params
    params.require(:contact_us).permit(:name, :email, :skype_id, :phone, :message,:organization, :job_title, :role)
  end

  def career_params
    params.require(:career).permit(:first_name, :last_name, :email, :contact_number, :current_company,
                                   :current_ctc, :linkedin_profile, :github_profile, :resume,
                                   :portfolio_link, :cover)
  end
end
