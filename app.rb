require 'active_support/security_utils'
require 'sinatra'
require 'mail'
require 'safe_yaml'
require 'json'

$config = SafeYAML.load_file('config.yaml')

mail_options = {
	:address => "smtp.gmail.com",
	:port => 587,
	:domain	=> 'gmail.com',
	:user_name => $config['username'],
	:password => $config['password'],
	:authentication => 'plain',
	:enable_starttls_auto => true
}

Mail.defaults do
  delivery_method :smtp, mail_options
end

def email(tracker)
	start = Time.now

	id = tracker['id']
	tracker_config = $config['trackers'][id]

	details = tracker['tracking_details'].last
	if !details
		return
	end

	mail = Mail.new do
		from $config['from']
	end

	if tracker_config
		mail['to'] = tracker_config['to']
		mail['subject'] = "#{tracker_config['description']} update"
	else
		mail['to'] = $config['to']
		mail['subject'] = "#{id} update"
	end

	mail['body'] = "#{details['message']}\n\nyour package is currently in #{details['tracking_location']['city']}, #{details['tracking_location']['state']}\n\nestimated delivery date: #{tracker['est_delivery_date']}\n\n#{tracker['public_url']}"
	mail.deliver!

	finish = Time.now
	puts "#{finish - start} seconds mailing"
end

post '/api/v1/easypost/webhook' do
	if request.content_type != 'application/json'
		halt 400
	end
	if !request.params.key?('secret') || !ActiveSupport::SecurityUtils.secure_compare(request.params['secret'], $config['secret'])
		halt 403
	end
	request.body.rewind
	data = JSON.parse request.body.read
	result = data['result']

	if result['object'] != 'Tracker'
		halt 204
	end

	Thread.new{email(result)}
	
	'sent'
end
