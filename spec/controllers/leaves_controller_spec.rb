require 'spec_helper'
require 'rake'
load File.expand_path("../../../lib/tasks/leave_reminder.rake", __FILE__)
describe LeaveApplicationsController do
  context "Employee, manager and HR" do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      hr = FactoryGirl.create(:hr)
      @user = FactoryGirl.create(:user, status: STATUS[:approved])
      @manager = FactoryGirl.create(:manager)
      sign_in @user
      @leave_application = FactoryGirl.build(:leave_application, user: @user)
    end

    it "should able to view new leave apply page" do
      get :new, {user_id: @user.id}
      should respond_with(:success)
      should render_template(:new)
    end

    context "leaves view" do
      before (:each) do
        @user.build_private_profile(
          FactoryGirl.build(:private_profile).attributes
        )
        @user.public_profile = FactoryGirl.build(:public_profile)
        @user.save
        @leave_application = FactoryGirl.build(:leave_application, user: @user)
        post :create, {
          user_id: @user.id,
          leave_application: @leave_application.attributes
        }
        user2 = FactoryGirl.create(:user, status: STATUS[:approved])
        user2.build_private_profile(
          FactoryGirl.build(:private_profile).attributes
        )
        user2.public_profile = FactoryGirl.build(:public_profile)
        user2.save
        @leave_application = FactoryGirl.build(:leave_application, user: user2)
        post :create, {
          user_id: user2.id,
          leave_application: @leave_application.attributes
        }
      end

      it "should show only his leaves if user is not admin" do
        get :view_leave_status
        expect(assigns(:pending_leaves).count).to eq(1)
      end

      it "user is admin he could see all leaves" do
        sign_out @user
        sign_in @admin
        get :view_leave_status
        expect(assigns(:pending_leaves).count).to eq(2)
      end

      it "user is manager then he could see all leaves" do
        sign_out @user
        sign_in @manager
        get :view_leave_status
        expect(assigns(:pending_leaves).count).to eq(2)
      end

      it 'should search all leaves if search parameters are empty' do
        sign_out @user
        sign_in @admin
        get :view_leave_status, { user_id: '', from: '', to: ''}
        expect(assigns(:pending_leaves).count).to eq(2)
      end

      # it 'should search leaves by employee first name' do
      #   sign_out @user
      #   sign_in @admin
      #   @user.public_profile.update(first_name: 'Test', last_name: 'Search')
      #   get :view_leave_status, { name: 'Test', from: '', to: ''}
      #   assigns(:pending_leaves).count.should eq(1)
      # end

      # it 'should search leaves by employee last name' do
      #   sign_out @user
      #   sign_in @admin
      #   @user.public_profile.update(first_name: 'Test', last_name: 'Search')
      #   get :view_leave_status, { name: 'Search', from: '', to: ''}
      #   assigns(:pending_leaves).count.should eq(1)
      # end

      it 'should search leaves by employee Id' do
        sign_out @user
        sign_in @admin
        get :view_leave_status, { user_id: @user.id, from: '', to: ''}
        expect(assigns(:pending_leaves).count).to eq(1)
      end

      # it 'should search leaves for case insensetive employee name' do
      #   sign_out @user
      #   sign_in @admin
      #   @user.public_profile.update(first_name: 'Test', last_name: 'Search')
      #   get :view_leave_status, { name: 'test search', from: '', to: ''}
      #   assigns(:pending_leaves).count.should eq(1)
      # end

      it 'should search leaves if some characters of employee name match' do
        sign_out @user
        sign_in @admin
        @user.public_profile.update(first_name: 'Test', last_name: 'Search')
        get :view_leave_status, { user_id: @user.id, from: '', to: ''}
        expect(assigns(:pending_leaves).count).to eq(1)
      end

      it 'should search leaves between from and to date' do
        sign_out @user
        sign_in @admin
        @leave_application = @leave_application.update(
          start_at: Date.today + 5.days,
          end_at: Date.today + 10.days
        )
        get :view_leave_status, {
          from: Date.today + 5.days,
          to: Date.today + 10.days
        }
        expect(assigns(:pending_leaves).count).to eq(1)
      end

      it 'should show leaves by employee name, leave start_date and end_date' do
        sign_out @user
        sign_in @admin
        @user.public_profile.update(first_name: 'Test', last_name: 'Search')
        leave_application = @user.leave_applications.first
        leave_application.update(
          start_at: Date.today + 5.days,
          end_at: Date.today + 10.days
        )
        get :view_leave_status, {
          user_id: @user.id,
          from: Date.today + 5.days,
          to: Date.today + 10.days
        }
        expect(assigns(:pending_leaves).count).to eq(1)
      end
    end

    it "should be able to apply for leave" do
      @user.build_private_profile(
        FactoryGirl.build(:private_profile).attributes
      )
      @user.public_profile = FactoryGirl.build(:public_profile)
      @user.save
      remaining_leave = @user.employee_detail.available_leaves -
        @leave_application.number_of_days
      post :create, {
        user_id: @user.id,
        leave_application: @leave_application.attributes
      }
      expect(LeaveApplication.count).to eq(1)
      @user.reload
      expect(@user.employee_detail.available_leaves).to eq(remaining_leave)
    end

    it "should not able to apply leave if not sufficient leave" do
      @user.build_private_profile(
        FactoryGirl.build(:private_profile).attributes
      )
      @user.public_profile = FactoryGirl.build(:public_profile)
      @user.save
      @user.employee_detail.update_attribute(:available_leaves, 1)
      post :create, {
        user_id: @user.id,
        leave_application: @leave_application.attributes
      }
      expect(LeaveApplication.count).to eq 0
      @user.reload
      expect(@user.employee_detail.available_leaves).to eq(1)
    end
  end

  context "AS HR" do
    before(:each) do
      admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:hr)
      sign_in @user
      @leave_application = FactoryGirl.create(:leave_application, user: @user)
    end

    it "should be able to apply leave" do
      get :new, {user_id: @user.id}
      should respond_with(:success)
      should render_template(:new)
    end
  end

  context "While accepting leaves" do
    before(:each) do
      @admin = FactoryGirl.create(:admin, status: STATUS[:approved])
      @hr = FactoryGirl.create(:hr)
      @user = FactoryGirl.create(:user)
      user1 = FactoryGirl.create(:user)

      project = FactoryGirl.create(:project, manager_ids: [@admin.id])
      FactoryGirl.create(:user_project, user_id: @user.id, project_id: project.id)
      FactoryGirl.create(:user_project, user_id: user1.id, project_id: project.id)

      sign_in @admin
    end

    it "Admin as a role should accept leaves " do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :approve
      }
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Approved"
    end

    it "Only single mail to employee should get sent on leave appproval" do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :approve
      }
      expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
    end

    it "Role(admin) should able to accept/reject as many times as he wants" do
      available_leaves = @user.employee_detail.available_leaves
      number_of_days = 2
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :approve
      }
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq("Approved")
      @user.reload
      expect(@user.employee_detail.available_leaves).
        to eq(available_leaves - number_of_days)
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :reject
      }
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq("Rejected")
      @user.reload
      expect(@user.employee_detail.available_leaves).to eq(available_leaves)
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :approve
      }
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq("Approved")
      @user.reload
      expect(@user.employee_detail.available_leaves).
        to eq(available_leaves - number_of_days)
    end

    it "should be able to apply leave" do
      get :new, {user_id: @admin.id}
      should respond_with(:success)
      should render_template(:new)
    end

    it "should be able to view all leaves" do
      leave_application_count = LeaveApplication.count
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      get :index
      expect(LeaveApplication.count).to eq(leave_application_count + 1)
      should respond_with(:success)
      should render_template(:index)
    end
  end

  context "Cancelling leaves," do
    it "Should be credited in corresponding account"
    it "Admin should be cancelled after accepting or rejecting"
    it "Employee should be able to cancel when leaves are not accepted/rejected"
    it "After accepting leaves, employee should not be able to cancel"
    it "If employee cancel leaves then admin should be notified"
    it "If Admin cancel leaves then employee should be notified"
  end

  context 'If user is not Admin should not able to ' do

    before do
      @user = FactoryGirl.create(:user)
      sign_in @user
    end

    after do
      expect(flash[:error]).to eq("Unauthorize access")
    end

    it ' Approve leave' do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :approve
      }
    end

    it ' Reject leave' do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :reject
      }
    end
  end

  context "Rejecting leaves" do

    before(:each) do
      @admin = FactoryGirl.create(:admin, status: STATUS[:approved])
      @hr = FactoryGirl.create(:hr)
      @user = FactoryGirl.create(:user)
      user1 = FactoryGirl.create(:user)

      project = FactoryGirl.create(:project, manager_ids: [@admin.id])
      FactoryGirl.create(:user_project, user_id: @user.id, project_id: project.id)
      FactoryGirl.create(:user_project, user_id: user1.id, project_id: project.id)
      sign_in @admin
    end

    it "Reason should get append on approval after rejection " do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      reason = 'Invalid Reason'
      xhr :get, :process_leave, {
        id: leave_application.id,
        reject_reason: reason,
        leave_action: :reject
      }
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Rejected"
      expect(leave_application.reject_reason).to eq reason
      xhr :get, :process_leave, {
        id: leave_application.id,
        reject_reason: reason,
        leave_action: :approve
      }
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Approved"
      expect(leave_application.reject_reason).to eq "#{reason};#{reason}"
    end

    it "Reason should get updated on rejection " do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      reason = 'Invalid Reason'
      xhr :get, :process_leave, {
        id: leave_application.id,
        reject_reason: reason,
        leave_action: :reject
      }
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Rejected"
      expect(leave_application.reject_reason).to eq reason
    end

    it "Only single mail to employee should get sent on leave rejection" do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :reject
      }
      expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
    end

    it 'it should not send mail to all teammates on leave rejection if employees leave was pending first' do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      project = FactoryGirl.create(:project)
      teammate1 = FactoryGirl.create(:user)
      FactoryGirl.build(:user_project, project_id: project.id, user_id: @user.id)
      FactoryGirl.build(:user_project, project_id: project.id, user_id: teammate1.id)
      expect(leave_application.leave_status).to eq(PENDING)
      ActionMailer::Base.deliveries = []
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :reject
      }
      expect(leave_application.reload.leave_status).to eq(REJECTED)
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it 'it should send mail to all teammates on leave rejection iff employees leave was accepted first' do
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      project = FactoryGirl.create(:project)
      teammate1 = FactoryGirl.create(:user)
      FactoryGirl.build(:user_project, project_id: project.id, user_id: @user.id)
      FactoryGirl.build(:user_project, project_id: project.id, user_id: teammate1.id)
      expect(leave_application.leave_status).to eq(PENDING)
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :approve
      }
      ActionMailer::Base.deliveries = []
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :reject
      }
      expect(leave_application.reload.leave_status).to eq(REJECTED)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it "should not deduct leaves if rejected already rejected leave" do
      available_leaves = @user.employee_detail.available_leaves
      number_of_days = 2
      leave_application = FactoryGirl.create(:leave_application, user: @user)
      @user.reload
      expect(@user.employee_detail.available_leaves).
        to eq(available_leaves-number_of_days)
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :reject
      }
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Rejected"
      @user.reload
      expect(@user.employee_detail.available_leaves).to eq(available_leaves)
      xhr :get, :process_leave, {
        id: leave_application.id,
        leave_action: :reject
      }
      leave_application = LeaveApplication.last
      expect(leave_application.leave_status).to eq "Rejected"
      @user.reload
      expect(@user.employee_detail.available_leaves).to eq(available_leaves)
    end
  end

  context 'Update', update_leave: true do
    let(:employee) { FactoryGirl.create(:user) }
    let(:leave_app) { FactoryGirl.create(:leave_application, user: employee) }

    it 'Admin should be able to update leave' do
      sign_in FactoryGirl.create(:admin)
      end_at, days = leave_app.end_at.to_date + 1.day,
        leave_app.number_of_days + 1
      post :update, id: leave_app.id, leave_application: {
        end_at: end_at,
        number_of_days: days
      }
      l_app = assigns(:leave_application)
      expect(l_app.number_of_days).to eq(days)
      expect(l_app.end_at).to eq(end_at)
    end

    it 'Employee should be able to update his own leave' do
      sign_in employee
      end_at, days = leave_app.end_at.to_date + 1.day,
        leave_app.number_of_days + 1
      post :update, id: leave_app.id, leave_application: {
        end_at: end_at,
        number_of_days: days
      }
      l_app = assigns(:leave_application)
      expect(l_app.number_of_days).to eq(days)
      expect(l_app.end_at).to eq(end_at)
    end

    it 'Employee should not be able to update leave of other employee' do
      sign_in FactoryGirl.create(:user)
      end_at, days = leave_app.end_at.to_date + 1.day,
        leave_app.number_of_days + 1
      post :update, id: leave_app.id, leave_application: {
        end_at: end_at,
        number_of_days: days
      }
      expect(flash[:alert]).
        to eq('You are not authorized to access this page.')
      l_app = assigns(:leave_application)
      expect(l_app.number_of_days).to eq(leave_app.number_of_days)
      expect(l_app.end_at).to eq(leave_app.end_at)
    end

    it 'number of days should get updated if updated' do
      sign_in employee
      number_of_leaves = employee.employee_detail.available_leaves
      end_at, days = leave_app.end_at.to_date + 1.day,
        leave_app.number_of_days + 1
      post :update, id: leave_app.id, leave_application: {
        end_at: end_at,
        number_of_days: days
      }
      l_app = assigns(:leave_application)
      expect(l_app.number_of_days).to eq(days)
      expect(l_app.end_at).to eq(end_at)
      expect(employee.reload.employee_detail.available_leaves).
        to eq(number_of_leaves - days)
    end
  end

  context 'Update', update_leave: true do
    let(:employee) { FactoryGirl.create(:user) }
    let(:leave_app) { FactoryGirl.create(:leave_application, user: employee) }

    it 'should update available leaves if number of days changed' do
      sign_in employee
      end_at, days = leave_app.end_at.to_date + 1.day,
        leave_app.number_of_days + 1
      employee.employee_detail.available_leaves = 10
      employee.save
      post :update, id: leave_app.id, leave_application: {
        end_at: end_at,
        number_of_days: days
      }
      expect(employee.reload.employee_detail.available_leaves).to eq(9)
    end

    it 'should not update if leave application is invalid' do
      sign_in employee
      leave_id = leave_app.id
      available_leaves = employee.employee_detail.available_leaves
      post :update, id: leave_id, leave_application: {
        end_at: leave_app.start_at - 1,
        number_of_days: 0
      }
      expect(flash[:error]).to eq("End at should not be less than start date.")
      should render_template(:edit)
      expect(employee.reload.employee_detail.available_leaves).to eq(available_leaves)
    end
  end

  context 'Leave type - WFH' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user, status: STATUS[:approved])
      @leave = FactoryGirl.build(
        :leave_application,
        leave_type: 'WFH',
        user: @user
      )
    end

    it 'should not deduct leave count while submitting form' do
      sign_in @user

      params = {
        user_id: @user.id,
        leave_application: @leave.attributes
      }
      post :create, params

      leave_count = @user.reload.employee_detail.available_leaves
      expect(flash[:success]).to eq('Your request has been submitted successfully.' +
        ' Please wait for the approval.')
      expect(@user.leave_applications.last.leave_status).to eq('Pending')
      expect(leave_count).to eq(24)
    end

    it 'should deduct leave count if leave type updated to LEAVE' do
      sign_in @user
      @leave.save
      leave_count = @user.employee_detail.available_leaves - @leave.number_of_days
      params = {
        id: @leave.id,
        leave_application: @leave.attributes.merge(leave_type: LEAVE_TYPES[:leave])
      }
      put :update, params

      expect(flash[:success]).to eq('Your request has been updated successfully.' +
        ' Please wait for the approval.')
      expect(@user.reload.employee_detail.available_leaves).to eq(leave_count)
      expect(@leave.reload.leave_type).to eq(LEAVE_TYPES[:leave])
    end

    it 'should not deduct leave count if leave type updated to Optional' do
      sign_in @user
      travel_to @leave.start_at - 1.month
      @leave.save
      leave_count = @user.employee_detail.available_leaves
      params = {
        id: @leave.id,
        leave_application: @leave.attributes.merge(leave_type: LEAVE_TYPES[:optional_holiday])
      }
      put :update, params
      travel_back
      expect(flash[:success]).to eq('Your request has been updated successfully.' +
        ' Please wait for the approval.')
      expect(@user.reload.employee_detail.available_leaves).to eq(leave_count)
      expect(@leave.reload.leave_type).to eq(LEAVE_TYPES[:optional_holiday])
    end

    it 'should not deduct leave count after approving the WFH request' do
      sign_in @admin
      @leave.save
      params = {
        id: @leave.id,
        leave_application: @leave.attributes.merge(leave_status: APPROVED)
      }
      put :update, params

      leave_count = @user.reload.employee_detail.available_leaves
      expect(flash[:success]).to eq('Your request has been updated successfully.' +
        ' Please wait for the approval.')
      expect(@leave.reload.leave_status).to eq(APPROVED)
      expect(leave_count).to eq(24)
    end
  end

  context 'Leave type - SPL' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user, status: APPROVED)
      @leave = FactoryGirl.build(
        :leave_application,
        leave_type: LEAVE_TYPES[:spl],
        user: @user
      )
    end

    it 'should not deduct leave count while submitting form' do
      sign_in @user

      post :create, {
        user_id: @user.id,
        leave_application: @leave.attributes
      }

      leave_count = @user.reload.employee_detail.available_leaves
      expect(flash[:success]).to eq('Your request has been submitted successfully.' +
        ' Please wait for the approval.')
      expect(@user.leave_applications.last.leave_status).to eq(PENDING)
      expect(leave_count).to eq(24)
    end

    it 'should not deduct leave count after approving the SPL request' do
      sign_in @admin
      @leave.save
      get :process_leave, {
        id: @leave.id,
        leave_action: :approve
      }

      leave_count = @user.reload.employee_detail.available_leaves
      expect(@leave.reload.leave_status).to eq(APPROVED)
      expect(leave_count).to eq(24)
    end
  end

  context 'Leave type - UNPAID' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user, status: APPROVED)
      @leave = FactoryGirl.build(
        :leave_application,
        leave_type: LEAVE_TYPES[:unpaid],
        user: @user
      )
    end

    it 'should not deduct leave count while submitting form' do
      sign_in @user

      post :create, {
        user_id: @user.id,
        leave_application: @leave.attributes
      }

      leave_count = @user.reload.employee_detail.available_leaves
      expect(flash[:success]).to eq('Your request has been submitted successfully.' +
        ' Please wait for the approval.')
      expect(@user.leave_applications.last.leave_status).to eq(PENDING)
      expect(leave_count).to eq(24)
    end

    it 'should not deduct leave count after approving the UNPAID request' do
      sign_in @admin
      @leave.save
      get :process_leave, {
        id: @leave.id,
        leave_action: :approve
      }

      leave_count = @user.reload.employee_detail.available_leaves
      expect(@leave.reload.leave_status).to eq(APPROVED)
      expect(leave_count).to eq(24)
    end
  end

  context "Leave history search querying user_ids" do
    before(:each) do
      @employee_one = FactoryGirl.create(:user, status: STATUS[:approved])
      @employee_two = FactoryGirl.create(:user, status: STATUS[:approved])
      @leave_app_one_one = FactoryGirl.create(:leave_application, user: @employee_one, start_at: Date.today + 1, end_at: Date.today + 4)
      @leave_app_one_two = FactoryGirl.create(:leave_application, user: @employee_one, start_at: Date.today + 5, end_at: Date.today + 8)
      @leave_app_two_one = FactoryGirl.create(:leave_application, user: @employee_two, start_at: Date.today + 9, end_at: Date.today + 12)
      @leave_app_two_one = FactoryGirl.create(:leave_application, user: @employee_two, start_at: Date.today + 13, end_at: Date.today + 16)
      @project = FactoryGirl.create(:project)
      @user_project_one = FactoryGirl.create(:user_project, user: @employee_one, project: @project, end_date: @project.end_date)
      @user_project_two = FactoryGirl.create(:user_project, user: @employee_two, project: @project)
    end

    it "should query only active user_projects when NO filter/default" do
      @user_ids = UserProject.where(project: @project).pluck(:user_id)
      @user_ids_active = (@user_ids - [@employee_two.id]) # Removing one team member
      @user_project_two.update_attributes(end_date: DateTime.now, active: false)
      controller.params = ActionController::Parameters.new({project_id: @project.id}) # No filter param
      expect(controller.send(:user_ids)).to eq(@user_ids_active)
    end

    it "should query only active user_projects when active filter selected in params" do
      @user_ids = UserProject.where(project: @project).pluck(:user_id)
      @user_ids_active = (@user_ids - [@employee_two.id]) # Removing one team member
      @user_project_two.update_attributes(end_date: DateTime.now, active: false)
      controller.params = ActionController::Parameters.new({active_or_all_flag: "active", project_id: @project.id})
      expect(controller.send(:user_ids)).to eq(@user_ids_active)
    end

    it "should query all user_projects when all filter selected in params" do
      @user_ids = UserProject.where(project: @project).pluck(:user_id)
      @user_ids_active = (@user_ids - [@employee_two.id]) # Removing one team member
      @user_project_two.update_attributes(end_date: DateTime.now, active: false)
      controller.params = ActionController::Parameters.new({active_or_all_flag: "all", project_id: @project.id})
      expect(controller.send(:user_ids)).to eq(@user_ids)
    end
  end

  context 'Overlapping Leave Request' do
    before(:each) do
      @user = FactoryGirl.create(:user, status: STATUS[:approved])
      @leave = FactoryGirl.build(:leave_application, user: @user)
      @start_date = Date.yesterday
      @end_date = Date.today + 7
      ActionMailer::Base.deliveries = []
      sign_in @user
    end

    it 'should be able to apply leave if overlapping WFH request is present' do
      FactoryGirl.create(:leave_application,
        start_at: @start_date,
        end_at: @end_date,
        leave_status: APPROVED,
        leave_type: LEAVE_TYPES[:wfh],
        user: @user
      )
      params = {
        user_id: @user.id,
        leave_application: @leave.attributes
      }
      post :create, params

      expect(flash[:success]).to eq('Your request has been submitted successfully.' +
        ' Please wait for the approval.')
      expect(@user.reload.leave_applications.pending.count).to eq(1)
      expect(@user.leave_applications.processed.count).to eq(1)
    end

    it 'should be able to apply SPL if overlapping WFH request is present' do
      FactoryGirl.create(:leave_application,
        start_at: @start_date,
        end_at: @end_date,
        leave_status: APPROVED,
        leave_type: LEAVE_TYPES[:wfh],
        user: @user
      )
      leave = FactoryGirl.build(
        :leave_application,
        start_at: Date.today,
        end_at: Date.today,
        user: @user,
        leave_type: LEAVE_TYPES[:spl]
      )
      params = {
        user_id: @user.id,
        leave_application: leave.attributes
      }
      post :create, params

      expect(flash[:success]).to eq('Your request has been submitted successfully.' +
        ' Please wait for the approval.')
      expect(@user.reload.leave_applications.pending.count).to eq(1)
      expect(@user.leave_applications.processed.count).to eq(1)
    end

    it 'should not be able to apply WFH request if overlapping Leave request is present' do
      FactoryGirl.create(:leave_application,
        start_at: @start_date,
        end_at: @end_date,
        leave_status: APPROVED,
        leave_type: LEAVE_TYPES[:leave],
        user: @user
      )
      @leave.update_attributes(leave_type: LEAVE_TYPES[:wfh])
      params = {
        user_id: @user.id,
        leave_application: @leave.attributes
      }
      post :create, params
      expect(flash[:error]).to eq('Already applied for LEAVE on same date')
      expect(@user.reload.leave_applications.pending.count).to eq(0)
      expect(@user.leave_applications.processed.count).to eq(1)
    end

    it 'should not be able to apply WFH request if overlapping SPL request is present' do
      FactoryGirl.create(:leave_application,
        start_at: @start_date,
        end_at: @end_date,
        leave_status: APPROVED,
        leave_type: LEAVE_TYPES[:spl],
        user: @user
      )
      @leave.update_attributes(leave_type: LEAVE_TYPES[:wfh])
      params = {
        user_id: @user.id,
        leave_application: @leave.attributes
      }
      post :create, params
      expect(flash[:error]).to eq('Already applied for SPL on same date')
      expect(@user.reload.leave_applications.pending.count).to eq(0)
      expect(@user.leave_applications.processed.count).to eq(1)
    end

    it 'should not be able to apply WFH request if overlapping WFH request is present' do
      FactoryGirl.create(:leave_application,
        start_at: @start_date,
        end_at: @end_date,
        leave_status: APPROVED,
        leave_type: LEAVE_TYPES[:wfh],
        user: @user
      )
      @leave.update_attributes(leave_type: LEAVE_TYPES[:wfh])
      params = {
        user_id: @user.id,
        leave_application: @leave.attributes
      }
      post :create, params
      expect(flash[:error]).to eq('Already applied for WFH on same date')
      expect(@user.reload.leave_applications.pending.count).to eq(0)
      expect(@user.leave_applications.processed.count).to eq(1)
    end

    it 'should not be able to apply leave request if overlapping Leave request is present' do
      FactoryGirl.create(:leave_application,
        start_at: @start_date,
        end_at: @end_date,
        leave_status: APPROVED,
        leave_type: LEAVE_TYPES[:leave],
        user: @user
      )
      params = {
        user_id: @user.id,
        leave_application: @leave.attributes
      }
      post :create, params
      expect(flash[:error]).to eq('Already applied for LEAVE on same date')
      expect(@user.reload.leave_applications.pending.count).to eq(0)
      expect(@user.leave_applications.processed.count).to eq(1)
    end
  end

  context 'Optional Leave' do
    before(:each) do
      @user = FactoryGirl.create(:user, status: STATUS[:approved])
      @optional_holiday = FactoryGirl.create(:holiday, holiday_date: Date.new(2021,2,9), holiday_type: HolidayList::OPTIONAL)
      travel_to @optional_holiday.holiday_date - 1.month
      @optional_leave = FactoryGirl.build(:leave_application,
        leave_type: LEAVE_TYPES[:optional_holiday],
        user: @user,
        start_at: @optional_holiday.holiday_date,
        end_at: @optional_holiday.holiday_date
      )
      @leave = FactoryGirl.build(:leave_application,
        leave_type: LEAVE_TYPES[:leave],
        user: @user,
        start_at: Date.new(2021,2,8),
        end_at: Date.new(2021,2,10),
        number_of_days: 3
      )
    end

    after do
      travel_back
    end

    it 'should not deduct any leave count' do
      sign_in @user
      leave_count = @user.employee_detail.available_leaves
      params = {
        user_id: @user.id,
        leave_application: @optional_leave.attributes
      }
      post :create, params

      expect(@user.reload.employee_detail.available_leaves).to eq(leave_count)
    end

    it 'should deduct leave if leave type updated to LEAVE' do
      sign_in @user
      @optional_leave.save
      leave_count = @user.employee_detail.available_leaves - @optional_leave.number_of_days
      params = {
        id: @optional_leave.id,
        leave_application: @optional_leave.attributes.merge(leave_type: LEAVE_TYPES[:leave])
      }
      put :update, params

      expect(@user.reload.employee_detail.available_leaves).to eq(leave_count)
      expect(@optional_leave.reload.leave_type).to eq(LEAVE_TYPES[:leave])
    end

    it 'should not deduct any leave if leave type updated to WFH' do
      sign_in @user
      @optional_leave.save
      leave_count = @user.employee_detail.available_leaves
      params = {
        id: @optional_leave.id,
        leave_application: @optional_leave.attributes.merge(leave_type: LEAVE_TYPES[:wfh])
      }
      put :update, params

      expect(@user.reload.employee_detail.available_leaves).to eq(leave_count)
      expect(@optional_leave.reload.leave_type).to eq(LEAVE_TYPES[:wfh])
    end

    it 'should not deduct leave count after approving the Optional request' do
      admin = FactoryGirl.create(:admin, status: STATUS[:approved])
      sign_in admin
      @optional_leave.save
      params = {
        id: @optional_leave.id,
        leave_action: :approve
      }
      xhr :get, :process_leave, params

      leave_count = @user.reload.employee_detail.available_leaves
      expect(@optional_leave.reload.leave_status).to eq(APPROVED)
      expect(@optional_leave.leave_type).to eq(LEAVE_TYPES[:optional_holiday])
      expect(leave_count).to eq(24)
    end

    it 'should not add or deduct leave count after reject the Optional request' do
      admin = FactoryGirl.create(:admin, status: STATUS[:approved])
      sign_in admin
      @optional_leave.save
      params = {
        id: @optional_leave.id,
        leave_action: :reject
      }
      xhr :get, :process_leave, params

      leave_count = @user.reload.employee_detail.available_leaves
      expect(@optional_leave.reload.leave_status).to eq(REJECTED)
      expect(@optional_leave.leave_type).to eq(LEAVE_TYPES[:optional_holiday])
      expect(leave_count).to eq(24)
    end

    it 'should deduct or add leave count of approved leave and' +
       ' increment or decreament available leaves of employee' +
       ' if the overlapping Optional leave is approved or rejected' do
      admin = FactoryGirl.create(:admin, status: STATUS[:approved])
      sign_in admin
      leave_count = @user.employee_detail.available_leaves
      @leave.save
      params = {
        id: @leave.id,
        leave_action: :approve
      }
      xhr :get, :process_leave, params
      expect(@user.reload.employee_detail.available_leaves).to eq(21)

      @optional_leave.save
      params = {
        id: @optional_leave.id,
        leave_action: :approve
      }
      xhr :get, :process_leave, params

      expect(@optional_leave.reload.leave_status).to eq(APPROVED)
      expect(@leave.reload.number_of_days).to eq(2)
      expect(@user.reload.employee_detail.available_leaves).to eq(22)
    end

    it 'should deduct or add leave count of rejected leave and' +
       ' if the overlapping Optional leave is approved or rejected' do
      admin = FactoryGirl.create(:admin, status: STATUS[:approved])
      sign_in admin
      leave_count = @user.employee_detail.available_leaves
      @leave.save
      params = {
        id: @leave.id,
        leave_action: :reject
      }
      xhr :get, :process_leave, params
      expect(@leave.reload.number_of_days).to eq(3)
      expect(@user.reload.employee_detail.available_leaves).to eq(24)

      @optional_leave.save
      params = {
        id: @optional_leave.id,
        leave_action: :approve
      }
      xhr :get, :process_leave, params

      expect(@optional_leave.reload.leave_status).to eq(APPROVED)
      expect(@leave.reload.number_of_days).to eq(2)
      expect(@user.reload.employee_detail.available_leaves).to eq(24)
    end
  end

  context 'Next year leave' do
    before(:each) do
      @user = FactoryGirl.create(:user, status: STATUS[:approved])
      @leave = FactoryGirl.build(:leave_application,
        leave_type: LEAVE_TYPES[:leave],
        user: @user,
        start_at: Date.today.next_year,
        end_at: (Date.today + 1).next_year
      )
      sign_in @user
    end

    it 'fail should as of applying date is greater than current year' do
      params = {
        user_id: @user.id,
        leave_application: @leave.attributes
      }
      post :create, params
      expect(flash[:error]).to eq('Invalid date, can not apply leave for the future year.')
    end
  end
end
