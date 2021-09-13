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

task :fetch_user_image => :environment do
  download_user_image = []
  user_name = []
  count = 0
  
  images = Dir.glob("/home/deploy/projects/intranet/josh_image/*")
  images.each do |image|
    download_user_image << image.split('/').last
  end
  
  User.approved.each do |user|
    image_path = user.public_profile.image.medium
    if image_path.present?
      file_path = image_path.path.split('/')
      next if download_user_image.include?(file_path.last)
  
      source_file = image_path.path
      destination_folder = "/home/deploy/projects/intranet/josh_new_image/"
  
      system("cp", source_file, destination_folder)
      user_name << user.name
      count += 1
    end
  end
  puts "Total Count: #{count}"
  puts user_name
end 
