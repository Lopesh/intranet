require 'rails_helper'

RSpec.describe TimeSheetsController, type: :controller do
  context 'create' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project, name: 'England Hockey', display_name: 'England_Hockey') }
    before do
      user.public_profile.slack_handle = USER_ID
      UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 2, end_date: nil)
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    it 'Should success' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      post :create, params
      resp = JSON.parse(response.body)
      expect(response).to have_http_status(:created)
      expect(resp['text']).to eq("*Timesheet saved successfully!*")
    end

    it 'should fail because validation trigger on timesheet data' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => 'England 14-07-2018  6 7 abcd efghigk lmnop' 
      }

      post :create, params
      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'Check user is exists' do
    let(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com') }
    let!(:project) { FactoryGirl.create(:project, name: 'England Hockey', display_name: 'England_Hockey') }
    before do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 2, end_date: nil)
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    it 'Associate slack id to user' do
      params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'user_id' => USER_ID,
        'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }
      post :create, params
      expect(response).to have_http_status(:created)
    end
  end

  context 'Timesheet: Daily status' do
    let(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com') }
    let!(:tpn) { FactoryGirl.create(:project, name: 'The pediatric network', display_name: 'The_pediatric_network') }

    context 'command with date option' do
      before do
        stub_request(:post, "https://slack.com/api/chat.postMessage")
        UserProject.create(user_id: user.id, project_id: tpn.id, start_date: DateTime.now - 2, end_date: nil)
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                                to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
      end

      it 'Should success : user worked on single project' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => Date.yesterday.to_s,
          'command' => '/daily_status'
        }

        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
        expect(response).to have_http_status(:ok)
      end

      it 'Should success : user worked on multiple projects' do
        deal_signal = FactoryGirl.create(:project, name: 'Deal signal', display_name: 'deal_signal')
        UserProject.create(user_id: user.id, project_id: deal_signal.id, start_date: DateTime.now - 4, end_date: nil)
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                                to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

        user.time_sheets.create(user_id: user.id, project_id: deal_signal.id,
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                                to_time: Time.parse("#{Date.yesterday} 12:00"), description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => Date.yesterday.to_s,
          'command' => '/daily_status'
        }
        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M* *Deal signal: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n2. Deal signal 11:00AM 12:00PM Today I finish the work \n")
      end

      it 'Should fail because invalid date' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => '06/13/2018'
        }

        post :daily_status, params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'command without date option' do
      before do
        UserProject.create(user_id: user.id, project_id: tpn.id, start_date: DateTime.now - 3, end_date: nil)
        stub_request(:post, "https://slack.com/api/chat.postMessage")
      end

      it 'Should success : user worked single project' do
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: Date.today, from_time: '9:00',
                                to_time: '10:00', description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }

        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
        expect(response).to have_http_status(:ok)
      end

      it 'Should success : user worked on multiple project' do
        deal_signal = FactoryGirl.create(:project, name: 'Deal signal', display_name: 'deal_signal')
        UserProject.create(user_id: user.id, project_id: deal_signal.id, start_date: DateTime.now - 3, end_date: nil)
        user.time_sheets.create!(user_id: user.id, project_id: tpn.id,
                                date: Date.today, from_time: "#{Date.today} 7:00",
                                to_time: "#{Date.today} 8:00", description: 'Today I finish the work')

        user.time_sheets.create!(user_id: user.id, project_id: deal_signal.id,
                                date: Date.today, from_time: "#{Date.today} 8:00",
                                to_time: "#{Date.today} 9:00", description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }
        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 00M* *Deal signal: 1H 00M*. Details are as follow\n\n1. The pediatric network 07:00AM 08:00AM Today I finish the work \n2. Deal signal 08:00AM 09:00AM Today I finish the work \n")
      end

      it 'Should fail because timesheet not present' do
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: Date.today - 1, from_time: '9:00',
                                to_time: '10:00', description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }

        post :daily_status, params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'index' do
    let!(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com', role: 'Admin') }
    let!(:tpn) { FactoryGirl.create(:project, name: 'The pediatric network', display_name: 'The_pediatric_network') }

    it 'Should success' do
      deal_signal = FactoryGirl.create(:project, name: 'Deal signal', display_name: 'deal_signal')
      UserProject.create(user_id: user.id, project_id: tpn.id, start_date: DateTime.now - 3, end_date: nil)
      UserProject.create(user_id: user.id, project_id: deal_signal.id, start_date: DateTime.now - 3, end_date: nil)
      user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

      user.time_sheets.create(user_id: user.id, project_id: deal_signal.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                              to_time: Time.parse("#{Date.yesterday} 12:00"), description: 'Today I finish the work')
      params = {from_date: Date.yesterday - 1, to_date: Date.today}
      sign_in user
      get :index, params
      expect(response).to have_http_status(200)
      should render_template(:index)
    end

    it 'Should return user specific timesheet ' do
      user = FactoryGirl.create(:user, email: 'vijay@joshsoftware.com', role: 'Employee')
      UserProject.create(user_id: user.id, project_id: tpn.id, start_date: Date.today - 3, end_date: nil)
      user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
      params = {from_date: Date.yesterday - 1, to_time: Date.today}
      sign_in user
      get :index, params
      expect(response).to have_http_status(200)
    end
  end

  context 'Show' do
    let!(:user) { FactoryGirl.create(:user, email: 'abc@joshsoftware.com', role: 'Admin') }
    let!(:tpn) { FactoryGirl.create(:project, name: 'The pediatric network', display_name: 'The_pediatric_network') }

    it 'users timesheet' do
      sign_in user
      deal_signal = FactoryGirl.create(:project, name: 'Deal signal', display_name: 'deal_signal')
      UserProject.create(user_id: user.id, project_id: tpn.id, start_date: DateTime.now - 3, end_date: nil)
      UserProject.create(user_id: user.id, project_id: deal_signal.id, start_date: DateTime.now - 3, end_date: nil)
      user.time_sheets.create!(project_id: tpn.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

      user.time_sheets.create!(project_id: deal_signal.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                              to_time: Time.parse("#{Date.yesterday} 12:00"), description: 'Today I finish the work')
      params = {user_id: user.id, from_date: Date.yesterday - 1, to_time: Date.today}
      get :users_timesheet, user_id: user.id, from_date: Date.yesterday - 1, to_date: Date.today
      expect(response).to have_http_status(200)
      should render_template(:users_timesheet)
    end
  end

  context 'Project report' do
    let!(:user_one) { FactoryGirl.create(:user, email: 'test1@joshsoftware.com', role: 'Admin') }
    let!(:user_two) { FactoryGirl.create(:user, email: 'test2@joshsoftware.com', role: 'Admin') }
    let!(:project) { FactoryGirl.create(:project, name: 'test') }
    
    it 'Should success' do
      UserProject.create(user_id: user_one.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: '05/09/2018'.to_date, end_date: '15/05/2018'.to_date)

      TimeSheet.create(user_id: user_one.id, project_id: project.id,
                              date: '10/09/2018'.to_date, from_time: "9:00",
                              to_time: "10:00", description: 'Today I finish the work')

      TimeSheet.create(user_id: user_two.id, project_id: project.id,
                              date: '11/09/2018'.to_date, from_time: "9:00",
                              to_time: "10:00", description: 'Today I finish the work')
      params = params = {from_date: Date.today.beginning_of_month.to_s, to_date: Date.today.to_s}
      sign_in user_one
      get :projects_report, params
      expect(response).to have_http_status(200)
      should render_template(:projects_report)
    end

    it 'Should fail because user is not authorized' do
      user_one.update_attributes(role: ROLE[:employee])
      UserProject.create(user_id: user_one.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      TimeSheet.create(user_id: user_one.id, project_id: project.id,
                              date: '10/09/2018'.to_date, from_time: "9:00",
                              to_time: "10:00", description: 'Today I finish the work')
      params = params = {from_date: Date.today.beginning_of_month.to_s, to_date: Date.today.to_s}
      sign_in user_one
      get :projects_report, params
      expect(response).to have_http_status(302)
    end
  end

  context 'Individual project report' do
    let!(:user) { FactoryGirl.create(:user, role: 'Admin') }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should success' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      TimeSheet.create(user_id: user.id, project_id: project.id,
                              date: '10/09/2018'.to_date, from_time: "9:00",
                              to_time: "10:00", description: 'Today I finish the work')
      sign_in user
      get :individual_project_report, id: project.id, from_date: '01/09/2018', to_date: '27/09/2018'
      expect(response).to have_http_status(200)
    end

    it 'Should fail because user is not authorized' do
      user = FactoryGirl.create(:user, role: 'Employee')
      UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      TimeSheet.create(user_id: user.id, project_id: project.id,
                              date: '10/09/2018'.to_date, from_time: "9:00",
                              to_time: "10:00", description: 'Today I finish the work')
      sign_in user
      get :individual_project_report, id: project.id, from_date: '01/09/2018', to_date: '27/09/2018'
      expect(response).to have_http_status(302)
    end
  end

  context 'Update timesheet' do
    let!(:user) { FactoryGirl.create(:user, email: 'abc@joshsoftware.com', role: 'Admin') }
    let!(:project) { FactoryGirl.create(:project, name: 'test') }
    let!(:employee) { FactoryGirl.create(:user) }

    it 'Should update timesheet' do
      sign_in user
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"#{Date.today - 1} - 09:00", "to_time"=>"#{Date.today - 1} - 11:15", "description"=>"testing API and call with client", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      put :update_timesheet, user_id: user.id, user: params, time_sheet_date: Date.today - 1
      expect(time_sheet.reload.from_time.to_s).to eq("#{Date.today - 1} - 09:00 AM")
      expect(time_sheet.reload.to_time.to_s).to eq("#{Date.today - 1} - 11:15 AM")
      expect(time_sheet.reload.description).to eq("testing API and call with client")
    end

    it 'Should not update timesheet because description is not present' do
      sign_in user
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"#{Date.today - 1} - 09:00 AM", "to_time"=>"#{Date.today - 1} - 11:15 AM", "description"=>"", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      post :update_timesheet, user_id: user.id, user: params, time_sheet_date: Date.today - 1
      expect(flash[:error]).to be_present
      should render_template(:edit_timesheet)
    end

    it 'Should not update timesheet because from time is not present' do
      sign_in user
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"", "to_time"=>"#{Date.today - 1} - 11:15 AM", "description"=>"testing API and call with client", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      post :update_timesheet, user_id: user.id, user: params, time_sheet_date: Date.today - 1
      expect(flash[:error]).to be_present
      should render_template(:edit_timesheet)
    end

    it 'Should not update timesheet because to time is not present' do
      sign_in user
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"#{Date.today - 1} - 09:00 AM", "to_time"=>"", "description"=>"testing API and call with client", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      post :update_timesheet, user_id: user.id, user: params, time_sheet_date: Date.today - 1
      expect(flash[:error]).to be_present
      should render_template(:edit_timesheet)
    end

    it 'Should not update Timesheet because timesheet date is less than 7 days' do
      sign_in user
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"#{Date.today - 1} - 11:00 AM", "to_time"=>"#{Date.today - 1} - 10:00 AM", "description"=>"testing API and call with client", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      post :update_timesheet, user_id: user.id, user: params, time_sheet_date: Date.today - 1
      expect(flash[:error]).to be_present
      should render_template(:edit_timesheet)
    end

    it 'Should update Timesheet because timesheet date is not less than 2 days in case of Employee' do
      sign_in employee
      UserProject.create(user_id: employee.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: employee.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"#{Date.today - 1} - 11:00 AM", "to_time"=>"#{Date.today - 1} - 10:00 AM", "description"=>"testing API and call with client", "id"=>"#{time_sheet.id}"}}, "id"=>employee.id}
      post :update_timesheet, user_id: employee.id, user: params, time_sheet_date: Date.today - 1
      expect(flash[:error]).not_to be_present
      should render_template(:edit_timesheet)
    end

    it 'Should not update Timesheet because timesheet date is less than 2 days in case of Employee' do
      sign_in employee
      UserProject.create(user_id: employee.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: employee.id, project_id: project.id, date: Date.today - 3, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"#{Date.today - 1} - 11:00 AM", "to_time"=>"#{Date.today - 1} - 10:00 AM", "description"=>"testing API and call with client", "id"=>"#{time_sheet.id}"}}, "id"=>employee.id}
      post :update_timesheet, user_id: employee.id, user: params, time_sheet_date: Date.today - 3
      expect(flash[:error]).to eql("Not allowed to edit timesheet for this date. You can edit timesheet for past #{TimeSheet::DAYS_FOR_UPDATE} days.")
      should render_template(:edit_timesheet)
    end

    it 'Should update Timesheet even if timesheet date is less than 2 days in case of Admin' do
      sign_in user
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 3, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"#{Date.today - 1} - 11:00 AM", "to_time"=>"#{Date.today - 1} - 10:00 AM", "description"=>"testing API and call with client", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      post :update_timesheet, user_id: user.id, user: params, time_sheet_date: Date.today - 3
      expect(flash[:error]).not_to be_present
      should render_template(:edit_timesheet)
    end
  end

  context 'Export project report' do
    let!(:user) { FactoryGirl.create(:user, role: 'Admin') }
    let!(:user_one) { FactoryGirl.create(:user, role: 'Employee') }
    let!(:user_two) { FactoryGirl.create(:user) }
    let!(:project) {FactoryGirl.create(:project)}

    it 'Should give the project report' do
      UserProject.create(user_id: user_one.id, project_id: project.id, start_date: Date.today - 20, end_date: nil)
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: Date.today - 20, end_date: nil)
      user_one.time_sheets.create!(project_id: project.id, date: Date.today - 2, from_time: "#{Date.today - 2} 10", to_time: "#{Date.today - 2} 11", description: 'Test api')
      user_one.time_sheets.create!(project_id: project.id, date: Date.today - 2, from_time: "#{Date.today - 2} 12", to_time: "#{Date.today - 2} 13", description: 'call with client')
      user_two.time_sheets.create!(project_id: project.id, date: Date.today - 2, from_time: "#{Date.today - 2} 10", to_time: "#{Date.today - 2} 11", description: 'test data')
      from_date = Date.today - 20
      to_date = Date.today
      sign_in user_one
      get :export_project_report, format: 'csv', from_date: from_date, to_date: to_date, project_id: project.id
      expect(response.body).to eq("Employee name,Date(dd/mm/yyyy),No of hours,Details\nfname lname,28-10-2018,2,\"Test api\ncall with client\"\nfname lname,28-10-2018,1,test data\n")
    end
  end

  context 'Add timesheet' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }

    before do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
    end

    it 'Should add timesheet' do
      params = { "time_sheets_attributes" => {"0" => {"project_id" => "#{project.id}", 
                 "date" => "#{Date.today - 1}", "from_time" => "#{Date.today - 1} - 10:00 AM", 
                 "to_time" => "#{Date.today - 1} - 11:00 AM", "description" => "testing API and call with client"}},
                 "user_id" => user.id, "from_date" => Date.today - 20, "to_date" => Date.today
                }
      sign_in user
      post :add_time_sheet, user_id: user.id, user: params
      expect(flash[:notice]).to be_present
      expect(user.reload.time_sheets[0].user_id).to eq(user.id)
      expect(user.time_sheets[0].project_id).to eq(project.id)
    end

    it 'Should not add timesheet because validation failure' do
      params = { "time_sheets_attributes" => {"0" => {"project_id" => "#{project.id}", 
                 "date" => "#{Date.today - 1}", "from_time" => "#{Date.today - 1} - 10:00", 
                 "to_time" => "#{Date.today - 1} - 09:00", "description" => "testing API and call with client"}},
                 "user_id" => user.id, "from_date" => Date.today - 20, "to_date" => Date.today
               }
      sign_in user
      post :add_time_sheet, user_id: user.id, user: params
      expect(flash[:error]).to be_present
      should render_template(:new)
    end
  end
end
