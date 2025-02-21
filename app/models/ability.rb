class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.role? 'Super Admin'
      can :manage, :all
    elsif user.role? 'Admin'
      admin_abilities
    elsif user.role? 'HR'
      hr_abilities(user.id)
    elsif user.role? 'Finance'
      can :edit, User
      can [:public_profile, :private_profile, :apply_leave, :users_optional_holiday_list], User
      can [:projects_report, :export_project_report], TimeSheet
      can [:individual_project_report], [TimeSheet, Project]
      can :read, :dashboard
      can [:index, :holiday_list], HolidayList
      can :manage, Company
      cannot :manage, LeaveApplication
      can [:new, :create], LeaveApplication, user_id: user.id
      can [:edit, :update], LeaveApplication, leave_status: 'Pending', user_id: user.id
    elsif user.role? 'Manager'
      employee_abilities(user.id)
      can :manage, Project
      can :edit, User
      can :manage, Company
      can [:public_profile, :private_profile, :apply_leave], User
      can :manage, TimeSheet
      can :manage, LeaveApplication
      can :resource_list, User
      can :manage, EntryPass

      # TODO remove later after snowflake changes
      can :manage, Designation
    elsif user.role? 'Employee'
      employee_abilities(user.id)
    elsif user.role? 'Consultant'
      consultant_abilities(user.id)
    elsif user.role? 'Intern'
      intern_abilities(user.id)
    end
  end

  def common_admin_hr
    can :invite_user, User
    can :manage, [Project]
    can :manage, [Attachment, Policy]
    can :manage, Vendor
    can :manage, LeaveApplication
    can :manage, Schedule
    can :manage, Company
    can :manage, TimeSheet
    can :manage, HolidayList
    can :manage, Designation
    can :resource_list, User
    can :manage, EntryPass
    can :read, :dashboard
  end

  def intern_abilities(user_id)
    can [:public_profile, :private_profile], User
    can :read, [Policy, Attachment, Vendor]
    can [:index, :users_timesheet, :edit_timesheet, :update_timesheet, :new, :add_time_sheet], TimeSheet, user_id: user_id
    can :manage, EntryPass, user_id: user_id
    can :read, :dashboard
    can :index, HolidayList
  end

  def employee_abilities(user_id)
    can [:public_profile, :private_profile, :apply_leave, :users_optional_holiday_list], User, id: user_id
    can [:index, :download_document], Attachment do |attachment|
      attachment.user_id == user_id || attachment.is_visible_to_all
    end
    can :read, Policy
    cannot :manage, LeaveApplication
    can [:new, :create], LeaveApplication, user_id: user_id
    can [:edit, :update], LeaveApplication, leave_status: 'Pending', user_id: user_id
    can :read, Vendor
    can [:index, :users_timesheet, :edit_timesheet, :update_timesheet, :new, :add_time_sheet], TimeSheet, user_id: user_id
    cannot [:projects_report, :individual_project_report], TimeSheet
    can :manage, EntryPass, user_id: user_id
    cannot :report, EntryPass
    can [:index, :holiday_list], HolidayList
    can :read, :dashboard
  end

  def consultant_abilities(user_id)
    can [:public_profile, :private_profile, :apply_leave, :users_optional_holiday_list], User, id: user_id
    cannot :manage, LeaveApplication
    can [:new, :create], LeaveApplication, user_id: user_id
    can [:edit, :update], LeaveApplication, leave_status: 'Pending', user_id: user_id
    can [:index, :users_timesheet, :edit_timesheet, :update_timesheet, :new, :add_time_sheet], TimeSheet, user_id: user_id
    cannot [:projects_report, :individual_project_report], TimeSheet
    cannot :manage, EntryPass, user_id: user_id
    cannot :report, EntryPass
    can [:index, :holiday_list], HolidayList
    cannot :read, :dashboard
    can [:index, :holiday_list], HolidayList
  end

  def admin_abilities
    common_admin_hr
    can :edit, User
    can [:public_profile, :private_profile, :users_optional_holiday_list], User
    can :manage, :admin
    can :manage, EntryPass
  end

  def hr_abilities(user_id)
    common_admin_hr
    can [:public_profile, :private_profile, :edit, :apply_leave, :users_optional_holiday_list], User
    cannot :manage, LeaveApplication
    can :index, LeaveApplication
    can [:new, :create], LeaveApplication, user_id: user_id
    can [:edit, :update], LeaveApplication, leave_status: 'Pending', user_id: user_id
  end
end
