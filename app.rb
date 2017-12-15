require 'sinatra'
require 'mail'
require 'safe_yaml'

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
	mail = Mail.new do
		from config['from']
		to config['to']
		subject 'easypost webhook'
	end
	mail['body'] = request.body.read.to_s
	mail.deliver!
end