require 'mongoid'
namespace :database_restoration do
  task dump_data: :environment do
    if Rails.env.development?
      def change_users_password_on_development_env
        User.each do |user|
          user.password = 'josh123'
          user.password_confirmation = 'josh123'
          user.save(validate: false)
        end
      end

      def change_sensitive_snowflake_info_development_env
        db = Mongoid::Sessions.default
        collection = db[:user_assessments]
        collection.find.update_all(:$set => { aspirations: "This is the aspirations field", 
                                      trainings: "This is the Trainigs Field",
                                      goals: "This is field to add your professional goals",
                                      manager_feedback: "This is a good employee",
                                      team_feedback: "We got such a good colleague",
                                      assessment_wise_designation: "Software Engineer"
                                 })

        collection = db[:manager_feedbacks]
        collection.find.update_all(:$set => { feedback: "This employee is very Active and Keep always positive attitude towards work." })
      
      end

      parent_directory = Pathname.getwd.parent
      if Dir.exists?("#{parent_directory}/intranet_db_dump")
        system("mongorestore --db intranet_development #{parent_directory}/intranet_db_dump")
        change_users_password_on_development_env
        change_sensitive_snowflake_info_development_env  
      else
        raise "Error: #{dirname} Directory not available in #{path}"
      end
    end
  end
end