# Sirsidynix

Work with Sirsidynix APIs

Currently supports Horizon Web Services only

In progress ...

## Installation

Add this line to your application's Gemfile:

    gem 'sirsidynix'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sirsidynix

## Usage

Initialize an API:

	api = Sirsidynix::HorizonWebAPI.new

Initialize a service:

	library = {
		host: 'http://catalog.yourlibrary.org',
		port: '80',
		name: 'hzws',
		clientid: 'yourClientID',
		jsonify: false,
		api: api,
		log: Logger.new(STDOUT),
	}
	hws = Sirsidynix::HorizonWebService.new library

Test the service:

	puts hws.version
	puts hws.search_by_title({ term: "hyperion" })

Initialize a user:

	user = Sirsidynix::HorizonWebUser.new({ card: '123456789', pin: '1234', service: hws })
	user.login
	puts "#{user.first} #{user.last}"
	puts user.location
	puts user.lookup_my_address_info
	puts user.lookup_my_lists
	user.logout

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
