task :replace_user_images => :environment do
  user_image = {}
  User.approved.each do |user|
    image = user.public_profile.image.medium
    if image.present?
      user_image.merge!(user.id.to_s => image.path)
    end
  end

  image_upload_user = []
  user_image.each do |user_id, path|
    user = User.find(user_id)
    file_path = path.split('/')
    source_file_path = "/home/deploy/projects/intranet/josh_image/" + "#{file_path.last}"
    destination_file_path = "#{Rails.root}/public/uploads/public_profile/image/" + "#{file_path[-2]}/"
    destination_file = destination_file_path + "#{file_path.last}"
    if File.exist?(source_file_path) && File.exist?(destination_file)
      system("cp", source_file_path, destination_file_path)
      image_upload_user << user.name
    else
      puts "\n"
      puts "Employee Name: #{user.name}"
      puts "source file path : #{source_file_path}"
      puts "destination file path : #{destination_file_path}#{file_path.last}" 
      puts "\n"
    end
  end
  puts "\n\nBelow Employee's profile images updated: \n"
  puts  image_upload_user
end