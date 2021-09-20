GENDER = ['Male', 'Female']
ADDRESSES = ['Permanent Address', 'Temporary Address']
BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
STATUS = {created: 'created', pending: 'pending', approved: 'approved', resigned: 'resigned'}
LEAVE_STATUS = ['Pending', 'Approved', 'Rejected']
INVALID_REDIRECTIONS = ["/users/sign_in", "/users/sign_up", "/users/password"]
TSHIRT_SIZE = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL']
OTHER = ['DevOps', 'QA-Automation', 'QA-Manual', 'UI/UX']
LANGUAGE = ['Go', 'Python', 'Ruby', 'Java', 'PHP', 'Android', 'iOS']
FRAMEWORK = ['ReactJs', 'Angular', 'Flutter', '.Net', 'NodeJs', 'React-Native']
PENDING = 'Pending'
APPROVED = 'Approved'
REJECTED = 'Rejected'
LOCATIONS = ['Bengaluru', 'Plano', 'Pune']
COUNTRIES = ['India', 'USA']
COUNTRIES_ABBREVIATIONS = ['IN', 'US']
CityCountryMapping = [
  { city: 'Bengaluru', country: 'India'},
  { city: 'Pune', country: 'India'},
  { city: 'Plano', country: 'USA'}
]

UI_UX_DESIGNATION = ['UI/UX Lead', 'UI/UX Designer', 'Senior UI/UX Designer']
QA_DESIGNATION = ['QA Lead', 'Senior QA Engineer', 'QA Engineer']
ORGANIZATION_DOMAIN = 'joshsoftware.com'
ORGANIZATION_NAME = 'Josh Software'

CONTACT_ROLE =  ["Accountant", "Technical", "Accountant and Technical"]

SLACK_API_TOKEN = ENV['SLACK_API_TOKEN']

ROLE = { admin: 'Admin', employee: 'Employee', HR: 'HR', manager: 'Manager',
         intern: 'Intern', team_member: 'team member', consultant: 'Consultant',
         finance: 'Finance' }

DIVISION_TYPES = {
  consultant: 'Consultant', digital: 'Digital', management: 'Management', project: 'Projects'
}

EMAIL_ADDRESS = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

DEFAULT_TIMESHEET_MANAGERS = ['pritam.pandit.jc@joshsoftware.com']

EXCEPTED_TIMESHEET_REMINDER_EMAILS = ['sameert@joshsoftware.com']

MANAGEMENT = ['Admin', 'HR', 'Manager', 'Finance']
TIMESHEET_MANAGEMENT = ['Admin', 'HR', 'Manager']

DOCUMENT_MANAGEMENT = ['Super Admin', 'Admin', 'HR']

DAILY_OFFICE_ENTRY_LIMIT = 30

OFFICE_ENTRY_PASS_MAIL_RECEPIENT=["shailesh.kalekar@joshsoftware.com", "sameert@joshsoftware.com", "hr@joshsoftware.com"]

ROLLBAR_ISSUES_URL = 'https://api.rollbar.com/api/1/items'

CUSTOM_MANAGERS = { 
  bengaluru: 'amit.singh@joshsoftware.com', ui_ux: 'sai@joshsoftware.com',
  admin: 'shailesh.kalekar@joshsoftware.com', default: 'sameert@joshsoftware.com'
}

LEAVE_TYPES = {leave: 'LEAVE', wfh: 'WFH', optional_holiday: 'OPTIONAL HOLIDAY', spl: 'SPL', unpaid: 'UNPAID'}

ASSESSMENT_MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
ASSESSMENT_PLATFORM = ['PLAI', 'Snowflake', 'None']

BIRTHDAY_TEMPLATES={template_0: {bg_color: '#62c4c8', bg_image: 'birthday-template-1@2x.png', photo_bg_color: '#4a9396', name_color: '#275355'},
                    template_1: {bg_color: '#97b58d', bg_image: 'birthday-template-2@2x.png', photo_bg_color: '#a9bca3', name_color: '#400003'},
                    template_2: {bg_color: '#b18c62', bg_image: 'birthday-template-6@2x.png', photo_bg_color: '#907e6a', name_color: '#ffffff'},
                    template_3: {bg_color: '#cc6d51', bg_image: 'birthday-template-7@2x.png', photo_bg_color: '#87c6a8', name_color: '#ffffff'},
                    template_4: {bg_color: '#31999d', bg_image: 'birthday-template-8@2x.png', photo_bg_color: '#00eaea', name_color: '#ffffff'}
                  }
#template_2: {bg_color: '#009fb0', bg_image: 'birthday-template-3@2x.png', photo_bg_color: '#65acc0', name_color: '#ffffff'},
#template_3: {bg_color: '#78689c', bg_image: 'birthday-template-4@2x.png', photo_bg_color: '#655884', name_color: '#ffffff'},
#template_4: {bg_color: '#4d8a8e', bg_image: 'birthday-template-5@2x.png', photo_bg_color: '#4a9396', name_color: '#ffffff'},
