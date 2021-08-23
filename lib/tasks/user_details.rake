require 'csv'
namespace :user_details do
  desc "Export user personal, private details in csv"
  task :export_user_details => :environment do
    file = "#{Rails.root}/public/user_details.csv"
    headers = ["Sr.No", "Employee ID", "Name", "Email", "Website sequence number", "Skype Id", "Pivotal Tracker Id", "Github Handle",
                "Twitter Handle", "GitLab Handle", "Bitbucket Handle", "Blog Url", "LinkedIn Url", "Facebook Url",
                "Slack Handle", "Tshirt Size", "Employee Location", "Designation Track", "Description", "Notification Email",
                "Is billable", "Joining Bonus Paid", "Permanent Address", "Permanent Address city", "Permanent Address pin code",
                "Permanent Address state", "Permanent Address mobile/landline no", "Temporary Address", "Temporary Address city",
                "Temporary Address pine code", "Temporary Address state", "Temporary Address mobile/landline no"
              ]
    CSV.open(file, 'w', write_headers: true, headers: headers) do | writer |
      User.employees.approved.each_with_index do |u,i|
        pri = u.private_profile
        pub = u.public_profile
        det = u.employee_detail

        address = []
        pri.addresses.each do |i|
          address << [i.address, i.city, i.state, i.landline_no, i.pin_code] if ADDRESSES.include?(i.type_of_address)
        end
        address.flatten!

        writer << [i+1, det.employee_id, u.name, u.email, u.try(:website_sequence_number), pub.try(:skype_id), pub.try(:pivotal_tracker_id), pub.try(:github_handle),
                   pub.try(:twitter_handle), pub.try(:gitlab_handle), pub.try(:bitbucket_handle), pub.try(:blog_url), pub.try(:linkedin_url), pub.try(:facebook_url), pub.try(:slack_handle),
                   pub.try(:tshirt_size), det.try(:location), det.try(:designation_track), det.try(:description), det.try(:notification_emails), det.try(:is_billable), 
                   det.try(:joining_bonus_paid), address[0], address[1], address[2], address[3], address[4], address[5], address[6], address[7], address[8], address[9]
                  ]
      end
    end
  end
end