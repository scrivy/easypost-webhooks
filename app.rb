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

	tracking_detail = result['tracking_details'].last
	if tracking_detail
		mail = Mail.new do
			from config['from']
			to config['to']
		end
		mail['subject'] = tracking_detail['message']
		mail['body'] = "#{tracking_detail['message']}\n\nyour package is currently in #{tracking_detail['tracking_location']['city']}\n\nestimated delivery date: #{result['est_delivery_date']}\n\n#{result['public_url']}"
		mail.deliver!
	end

	204
end
