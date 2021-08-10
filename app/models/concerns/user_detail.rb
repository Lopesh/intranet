module UserDetail
  extend ActiveSupport::Concern

  included do
    field :dob_day, type: Integer
    field :dob_month, type: Integer   
    field :doj_day, type: Integer
    field :doj_month, type: Integer

    embeds_one :public_profile, cascade_callbacks: true
    embeds_one :private_profile, cascade_callbacks: true
    embeds_one :employee_detail, cascade_callbacks: true

    accepts_nested_attributes_for :private_profile, reject_if: :all_blank, allow_destroy: true 
    accepts_nested_attributes_for :public_profile, reject_if: :all_blank, allow_destroy: true
    accepts_nested_attributes_for :employee_detail, reject_if: :all_blank, :allow_destroy => true
  end

  def delete_team_cache
    Rails.cache.delete('views/website/team.json')
  end

  module ClassMethods    

    def save_access_token(auth, user)
      #user.access_token= auth[:credentials][:token] 
      #user.expires_at= auth[:credentials][:expires_at]
      #user.refresh_token= auth[:credentials][:refresh_token]
      p "EXPIRES_AT"
      p auth[:credentials][:expires_at]
      p "TIME NOW"
      p Time.now.to_i
      p user
      user.update_attributes(access_token: auth[:credentials][:token], expires_at: auth[:credentials][:expires_at], refresh_token: auth[:credentials][:refresh_token]) if user.present?
      user
    end

    def from_omniauth(auth)
      if auth.info.email.include? "joshsoftware.com"
        user = User.where(email: auth.info.email).first
        save_access_token(auth, user)
        create_public_profile_if_not_present(user, auth)
        user
      else
        false
      end
    end

    def create_public_profile_if_not_present(user, auth)
      if user && !user.public_profile?
        user.build_public_profile(first_name: auth.info.first_name, last_name: auth.info.last_name).save
        user.update_attributes(provider: auth.provider, uid: auth.uid)
      end
    end

    def send_birthdays_wish
      user_ids = User.approved.where(dob_month: Date.today.month, dob_day: Date.today.day).map(&:id)
      if user_ids.present?
        user_ids.each do |user_id|
          current_template_id = BirthdayTemplate.first.current_template_id
          current_template = "template_" + "#{current_template_id}"
          UserMailer.birthday_wish(user_id, current_template).deliver
          next_template_id = (current_template_id+1) % BIRTHDAY_TEMPLATES.count
          BirthdayTemplate.update(current_template_id: next_template_id)
        end
      end
    end

    def send_year_of_completion
      users = User.approved.where(doj_month: Date.today.month, doj_day: Date.today.day, :role.ne => 'Intern')
      current_year = Date.today.year
      user_hash = {}
      users.each do |user|
        completion_year = current_year - user.private_profile.date_of_joining.year
        if completion_year > 0
          name = user.name.blank? ? user.email : user.name
          user_hash[completion_year].nil? ? user_hash[completion_year] = [name] : user_hash[completion_year] << name
        end
      end
      UserMailer.year_of_completion_wish(user_hash).deliver unless user_hash.blank?
    end

  end
end
