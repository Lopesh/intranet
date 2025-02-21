class UserMailer < ActionMailer::Base
  default from: 'intranet@joshsoftware.com',
          reply_to: 'hr@joshsoftware.com'

  def invitation(sender_id, receiver_id)
    @sender = User.where(id: sender_id).first
    @receiver = User.where(id: receiver_id).first
    mail(from: @sender.email, to: @receiver.email, subject: 'Invitation to join Josh Intranet')
  end

  def verification(updated_user_id)
    admin_emails = User.approved.where(role: 'Admin').all.map(&:email)
    @updated_user = User.where(id: updated_user_id).first
    hr = User.approved.where(role: 'HR').first
    receiver_emails = [admin_emails, hr.email].flatten.join(',')
    mail(to: receiver_emails , subject: "#{@updated_user.public_profile.name} Profile has been updated")
  end

  def leave_application(sender_email, receivers, leave_application_id, reminder = false)
    @user = User.find_by(email: sender_email)
    @projects = @user.projects.where(is_active: 'true').pluck(:name)
    @project_ids = @user.projects.where(is_active: 'true').pluck(:id)
    @managed_projects = @user.managed_projects.where(:id.nin => @project_ids, is_active: 'true').pluck(:name)
    @receivers = receivers
    @notification_names = @user.employee_detail.present? ? @user.employee_detail.get_notification_names : []
    @older_leaves = LeaveApplication.get_users_past_leaves(@user.id)
    @next_planned_leaves = LeaveApplication.get_users_upcoming_leaves(@user.id).nin(
      id: leave_application_id
    )
    @leave_application = LeaveApplication.where(id: leave_application_id).first
    @leave_type = get_leave_type(@leave_application.leave_type)
    if reminder
      mail(to: receivers, subject: "REMINDER : #{@user.name} has applied for #{@leave_type}")
    else
      mail(from: @user.email, to: receivers, subject: "#{@user.name} has applied for #{@leave_type}")
    end
  end

  def reject_leave(leave_application_id)
    get_leave(leave_application_id)
    mail(to: @notification_emails, subject: "#{@leave_type} Request got rejected")
  end

  def accept_leave(leave_application_id)
    get_leave(leave_application_id)
    mail(to: @notification_emails, subject: "Your #{@leave_type} request has been approved")
  end

  def send_accept_leave_notification(leave_id, emails)
    get_leave(leave_id)
    message = get_leave_message
    @leave_message = ['tomorrow.','today.'].include?(message) ? 'for ' + message : message
    mail(to: emails, subject: "Approved Leave Application - #{@user.name}")
  end

  def send_reject_leave_notification(leave_id, emails)
    get_leave(leave_id)
    message = get_leave_message
    @leave_message = ['tomorrow.','today.'].include?(message) ? 'for ' + message : message
    mail(to: emails, subject: "Leave Application Cancelled - #{@user.name}")
  end

  def send_approved_leave_notification(leave_id, emails)
    get_leave(leave_id)
    @leave_message = get_leave_message
    mail(to: emails, subject: "Employee on Leave - #{@user.name}")
  end

  def download_notification(downloader_id, document_name)
    @downloader = User.find(downloader_id)
    @document_name = document_name
    hr = User.approved.where(role: 'HR').try(:first).try(:email) || 'hr@joshsoftware.com'
    mail(to: hr, subject: "Intranet: #{@downloader.name} has downloaded #{document_name}")
  end

  def birthday_wish(user_id, birthday_templete, test_birthday)
    @birthday_user = User.find(user_id)
    @current_template = BIRTHDAY_TEMPLATES[:"#{birthday_templete}"]
    @image = @birthday_user.public_profile.image.medium
    if @image.present?
      attachments.inline['user.jpg'] = File.read(@image.path)
    else
      attachments.inline['user.jpg'] = File.read("#{Rails.root}/app/assets/images/user_dummy_image.jpg")
    end

    if test_birthday
      mail = [
        'swapnil@joshsoftware.com', 'rohit.nale@joshsoftware.com', 'sai@joshsoftware.com',
        'neha.naghate@joshsoftware.com', 'amar.chavan@joshsoftware.com',
        'sangeeta.yadav@joshsoftware.com', 'rupesh.gadekar@joshsoftware.com',
        'shrikant.gadekar@joshsoftware.com', 'seema@joshsoftware.com'
      ]
      mail(to: mail, subject: "TEST EMAIL TOMORROW'S BIRTHDAY: Happy Birthday #{@birthday_user.name}")
    else
      mail(to: 'all@joshsoftware.com', subject: "Happy Birthday #{@birthday_user.name}")
    end
  end

  def year_of_completion_wish(user_hash)
    @user_hash = user_hash
    mail(to: 'all@joshsoftware.com', subject: "Congratulations #{@user_hash.collect{|k, v| v }.flatten.join(', ')}")
  end

  def leaves_reminder(leaves, leave_type)
    get_leave_details(leaves)
    @leave_type = leave_type
    mail(to: @receiver_emails, subject: "Employees on #{@leave_type.downcase} tomorrow.")
  end

  def optional_holiday_reminder_next_month(leaves, date)
    get_leave_details(leaves)
    mail(to: @receiver_emails, subject: "List of employees on optional holiday - #{date.to_date.strftime("%b '%y")}.")
  end

  def invalid_blog_url(user_id)
    @user = User.where(id: user_id).first
    hr_emails = User.get_hr_emails
    @receiver_emails = [hr_emails, @user.email].flatten.join(',')
    mail(to: @receiver_emails, subject: 'Invalid Blog URL')
  end

  def new_blog_notification(params)
    body = <<-body
      #{params[:post_url]}
    body

    mail(subject: "New blog '#{params[:post_title]}' has been published", body: body,
         to: 'all@joshsoftware.com')
  end

  def new_policy_notification(policy_id)
    @policy = Policy.find(policy_id)
    mail(subject: 'New policy has been added',to: 'all@joshsoftware.com' )
  end

  def database_backup(path, file_name)
    attachments[file_name] = File.read("#{path}/#{file_name}")
    mail(subject: 'Josh Intranet: Daily database backup', to: ADMIN_EMAILS)
  end

  def profile_updated(changes, user_name)
    changes.delete('updated_at')
    @changes = changes.to_a
    hr = User.approved.where(role: 'HR').try(:first).try(:email) || 'hr@joshsoftware.com'
    @user_name = user_name
    mail(subject: 'Profile updated', to: hr)
  end

  def pending_leave_reminder(user, managers, leave)
    @user     = user
    hr_emails = User.get_hr_emails
    @leave    = leave
    mail(
      subject: 'Action Required on Pending Leave Requests',
      to: managers,
      cc: hr_emails
    )
  end

  def new_entry_passes(entry_passes_ids)
    @entry_passes = EntryPass.where(:id.in => entry_passes_ids).sort_by(&:date)
    @user = @entry_passes.first.user
    emails = [@user.email, 'seema@joshsoftware.com']
    mail(
      subject: "Office Entry Pass created by #{@user.name}",
      to: [OFFICE_ENTRY_PASS_MAIL_RECEPIENT, emails].flatten
    )
  end

  def delete_office_pass(date, user_id, deleted_by)
    @date = date
    @user = User.find(user_id)
    @deleted_by = User.find(deleted_by)
    mail(
      subject: 'Your office entry pass is deleted',
      to: @user.email,
      cc: User.get_hr_emails
    )
  end

  def notify_probation(users, date)
    @users    = users
    @date     = date
    hr_emails = User.get_hr_emails
    mail(
      subject: 'Action Required: Probation period of employees ending soon',
      to: hr_emails
    )
  end

  private

  def get_leave_details(leaves)
    user_ids = leaves.map(&:user_id)
    @receiver_emails = User.leave_notification_emails(user_ids)
    leaves.map do |leave|
      leave.sanctioning_manager = User.where(id: leave.processed_by).first.try(:name)
    end
    @leaves = leaves
  end

  def get_leave(id)
    @leave_application = LeaveApplication.where(id: id).first
    @leave_type = get_leave_type(@leave_application.leave_type)
    @user = @leave_application.user
    @processed_by = User.find(@leave_application.processed_by)
    @notification_emails = [
      @user.email,
      User.leave_notification_emails(@user.id)
    ].flatten.compact.uniq.join(', ')
  end

  def get_leave_type(leave_type)
    leave_type == LEAVE_TYPES[:wfh] ? leave_type : LEAVE_TYPES[:leave].capitalize
  end

  def get_leave_message
    start_date = @leave_application.start_at
    end_date = @leave_application.end_at
    leave_count = @leave_application.leave_count
    if leave_count == 1 && start_date == Date.tomorrow
      'tomorrow.'
    elsif leave_count == 1 && start_date == Date.today
      'today.'
    elsif leave_count == 1
      "for #{start_date}."
    else
      "from #{start_date} to #{end_date}."
    end
  end
end
