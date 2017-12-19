require 'active_support/security_utils'
require 'sinatra'
require 'mail'
require 'safe_yaml'
require 'json'

config = SafeYAML.load_file('config.yaml')

mail_options = {
	:address => "smtp.gmail.com",
	:port => 587,
	:domain	=> 'gmail.com',
	:user_name => config['username'],
	:password => config['password'],
	:authentication => 'plain',
	:enable_starttls_auto => true
}

Mail.defaults do
  delivery_method :smtp, mail_options
end

post '/api/v1/easypost/webhook' do
	if request.content_type != "application/json"
		halt 400
	end
	if !request.params.key?('secret') || !ActiveSupport::SecurityUtils.secure_compare(request.params['secret'], config['secret'])
		halt 403
	end
	request.body.rewind
	data = JSON.parse request.body.read
	result = data['result']
	mail = Mail.new do
		from config['from']
		to config['to']
	end
	mail['subject'] = result['id']
	mail['body'] = result
	mail.deliver!
end