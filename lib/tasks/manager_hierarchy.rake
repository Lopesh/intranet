namespace :user_manager do
  task user_data: :environment do
    manager_email = []
    User.all.each do |user|
      manager_email << user.employee_detail.try(:notification_emails)
    end

    Project.all_active.each do |project|
      manager_email << project.managers.pluck(:email)
    end

    manager_email = manager_email.compact.flatten.uniq.sort
    manger_names = {}

    manager_email.each do |manager|
      manager_details = User.where(email: manager)
      manger_name = manager_details.first.name
      managed_projects = manager_details.first.try(:managed_projects)
      manger_names[manger_name] = []

      managed_projects.each do |project|
        manger_names[manger_name] << project.users.collect(&:name)
      end

      manger_names[manger_name] << User.approved.where('employee_detail.notification_emails': manager_details.first.email).collect(&:name)
      manger_names[manger_name] = manger_names[manger_name].compact.flatten.uniq.sort
    end

    file    = "#{Rails.root}/public/user_hierarchy.csv"
    headers = ["Manager Name", "Employee Name"]
    csv  = CSV.read(file, skip_blanks: true, headers: true)
    CSV.open(file, 'w', write_headers: true, headers: headers) do | writer |
      manger_names.each do |manager_name, employee_name|
        writer << [manager_name, employee_name.shift]
        employee_name.each do |name|
          writer << ["", name]
        end
      end
    end
  end
end
