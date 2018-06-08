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
	if request.content_type != 'application/json'
		halt 400
	end
	if !request.params.key?('secret') || !ActiveSupport::SecurityUtils.secure_compare(request.params['secret'], config['secret'])
		halt 403
	end
	request.body.rewind
	data = JSON.parse request.body.read
	result = data['result']

	if result['object'] != 'Tracker'
		halt 204
	end

	tracker_id = result['id']
	tracker_config = config['trackers'][tracker_id]
	tracking_detail = result['tracking_details'].last

	if tracking_detail
		mail = Mail.new do
			from config['from']
		end

		if tracker_config
			mail['to'] = tracker_config['to']
			mail['subject'] = "#{tracker_config['description']} update"
		else
			mail['to'] = config['to']
			mail['subject'] = "#{tracker_id} update"
		end

		mail['body'] = "#{tracking_detail['message']}\n\nyour package is currently in #{tracking_detail['tracking_location']['city']}\n\nestimated delivery date: #{result['est_delivery_date']}\n\n#{result['public_url']}"
		mail.deliver!
	end

	'sent'
end
