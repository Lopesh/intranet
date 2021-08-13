FactoryGirl.define do
  factory :private_profile do
    pan_number { Faker::Code.nric }
    personal_email { Faker::Internet.email }
    passport_number { Faker::Code.nric }
    qualification { Faker::Educator.course }
    date_of_joining { Date.new(Date.today.year - 5, 01, 01) }
    previous_work_experience { Faker::Number.between(1, 15) }
  end
end
