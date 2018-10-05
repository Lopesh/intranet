desc 'Send weekly timesheet report to managers'
task :weekly_timesheet_report => :environment do
  from_date = Date.today - 7.days
  to_date = Date.today - 1.days
  mananers = User.where(role: 'Manager', status: STATUS[2])
  TimeSheet.get_project_and_generate_weekly_report(mananers, from_date, to_date)
end