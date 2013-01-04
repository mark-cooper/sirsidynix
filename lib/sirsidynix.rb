require "sirsidynix/version"
require "nokogiri"
require "open-uri"
require "logger"

module Sirsidynix

  module Request

    REQUESTS = {
      'HTML' => Proc.new { |doc| Nokogiri::HTML(doc) },
      'XML'  => Proc.new { |doc| Nokogiri::XML(doc) },
    }

    def execute(query, type = 'HTML', headers = {})
      raise "UNDEFINED REQUEST TYPE\t#{type}" unless REQUESTS.has_key? type
      doc = open(query, headers)
      REQUESTS[type].call doc
    end

  end

  module Response

    def respond(result, key = nil)
      return result unless key
      return result.css key
    end

    def parse(result, elements)
      result.children.find_all { |f| elements.include? f.name }
    end

  end

  class HorizonWebAPI

    attr_reader :api, :helpers

    def initialize
      @api = {
        'cancel_hold' => {
          method: 'cancelMyHold',
          args: ['holdKey'],
          response: 'HTML',
          token: true,
          secret: false,
          key: 'body',
          version: '1.0',
        },        
        'create_hold' => {
          method: 'createMyHold',
          args: ['pickupLocation', 'titleKey', 'itemKey'],
          response: 'HTML',
          token: true,
          secret: false,
          key: 'body',
          version: '1.0',          
        }, 
        'email_my_pin' => {
          method: 'emailMyPin',
          args: ['login'],
          response: 'XML',
          token: true,
          secret: true,
          key: nil,
          version: '1.2',
        },
        'get_my_list' => {
          method: 'getMyList',
          args: ['listKey'],
          response: 'XML',
          token: true,
          secret: false,
          key: 'ns1|GetMyListResponse',
          version: '1.0',          
        },        
        'login_user' => {
          method: 'loginUser',
          args: ['login', 'password'],
          response: 'XML',
          token: false,
          secret: false,
          key: 'LoginUserResponse',
          version: '1.0',
        },
        'logout_user' => {
          method: 'logoutUser',
          args: [],
          response: 'XML',
          token: true,
          secret: false,
          key: nil,
          version: '1.0',
        },
        'lookup_my_account_info' => {
          method: 'lookupMyAccountInfo',
          args: ['includeHoldInfo', 'includeAddressInfo', 'includeBlockInfo', 'includeItemsOutInfo'],
          response: 'XML',
          token: true,
          secret: false,
          key: 'LookupMyAccountInfoResponse',
          version: '1.0',
        },
        'lookup_my_lists' => {
          method: 'lookupMyLists',
          args: [],
          response: 'XML',
          token: true,
          secret: false,
          key: 'list',
          version: '1.0',
        },
        'lookup_title_info' => {
          method: 'lookupTitleInfo',
          args: ['titleKey', 'includeItemInfo', 'includeHoldCount'],
          response: 'XML',
          token: false,
          secret: false,
          key: 'titleInfo',
          version: '1.0',          
        },
        'renew_my_checkout' => {
          method: 'renewMyCheckout',
          args: ['barcode'],
          response: 'XML',
          token: true,
          secret: false,
          key: 'RenewMyCheckoutResponse',
          version: '1.0',          
        },        
        'search_catalog' => {
          method: 'searchCatalog',
          args: ['term', 'indexID', 'startHit', 'hitsToDisplay'],
          response: 'XML',
          token: false,
          secret: false,
          key: 'titleInfo',
          version: '1.0',          
        },
        'version' => {
          method: 'version',
          args: [],
          response: 'XML',
          token: false,
          secret: false,
          key: 'VersionResponse',
          version: '1.0',    
        },        
      }

      # retrieve = sub-element(s) to select, or nil for all
      @helpers = {
        'login_user' => {
            method: 'login_user',
            args: {
              login: '',
              password: '',
            },
            retrieve: ['sessionToken'],
        },
        'logout' => {
          method: 'logout_user',
          args: {},
          retrieve: nil,
        },
        'lookup_my_info' => {
          method: 'lookup_my_account_info',
          args: {
            includeHoldInfo: true,
            includeAddressInfo: true,
            includeBlockInfo: true,
            includeItemsOutInfo: true,
          },
          retrieve: ['HoldInfo', 'AddressInfo', 'BlockInfo', 'ItemsOutInfo'],
        },
        'lookup_my_holds_info' => {
          method: 'lookup_my_account_info',
          args: { includeHoldInfo: true },
          retrieve: ['HoldInfo'],
        },
        'lookup_my_address_info' => {
          method: 'lookup_my_account_info',
          args: { includeAddressInfo: true },
          retrieve: ['AddressInfo'],
        },
        'search_by_author' => {
          method: 'search_catalog',
          args: {
            term: '',
            indexID: '.AW',
          },
          retrieve: nil,
        },        
        'search_by_isbn' => {
          method: 'search_catalog',
          args: {
            term: '',
            indexID: 'ISBNEX',
          },
          retrieve: nil,
        },
        'search_by_title' => {
          method: 'search_catalog',
          args: {
            term: '',
            indexID: '.TW',
          },
          retrieve: nil,
        },
      }
    end

  end

  class HorizonWebService

    include Request
    include Response

    attr_reader :config, :api, :helpers, :url, :log
    attr_accessor :token, :jsonify

    def initialize(args)
      @config = defaults.merge args
      @api = config[:api].api
      @helpers = config[:api].helpers
      @token = ''
      @jsonify = config[:jsonify]
      @log = config[:log]
      @url = "#{config[:host]}:#{config[:port].to_s}/#{config[:name]}/#{config[:protocol]}/#{config[:service]}/"
    end

    def defaults
      {
        host: '',
        port: '80',
        name: '',
        clientid: '',
        secret: '',
        protocol: 'rest',
        service: 'standard',
        use_key: true,
        jsonify: false, # could use formatter instead
        api: nil,
        log: Logger.new(File.open(File::NULL, 'w')),
      }
    end

    def headers
      {
        "x-sirs-clientID" => config[:clientid],
        "x-sirs-sessionToken" => token,
        "x-sirs-secret" => config[:secret],
      }
    end

    def to_json
      puts "JSON"
    end

    def query(method, args = nil, selectors = nil)
      raise 'API METHOD ERROR' unless api.has_key? method
      raise 'SESSION ERROR' if api[method][:token] and token.empty?
      raise 'SECRET ERROR' if api[method][:secret] and config[:secret].empty?

      q = url + api[method][:method]
      if args
        q += '?'
        args.each do |k, v|
          if api[method][:args].include? k.to_s
            q += "#{k.to_s}=#{v}&"
          end
        end
      end

      log.info q
      r = execute URI::encode(q), api[method][:response], headers
      key = api[method][:key] if config[:use_key]
      r = respond r, key
      r = parse r, selectors if selectors
      r = to_json r if jsonify
      r
    end

    def _parse(name, *args)
      if helpers.has_key? name.to_s
        a = helpers[name.to_s][:args]
        a = a.merge args[0] if args[0]
        # this changes args
        args = [ a ]
        retrieve = helpers[name.to_s][:retrieve]
        # this changes name
        name = helpers[name.to_s][:method]
      end
      query name.to_s, args[0], retrieve
    end

    def method_missing(name, *args, &block)
      _parse name, *args
    end
    
  end

  class HorizonWebUser

    attr_reader :card, :pin, :service, :first, :last, :location

    def initialize(args)
      @card = args[:card]
      @pin = args[:pin]
      @service = args[:service]
    end

    def login
      r = login_user({ login: card, password: pin })
      service.token = r[0].text
      @location = lookup_my_account_info.css('locationID').text
      @last, @first = lookup_my_account_info.css('name').text.split(',').map(&:strip)
    end

    def place_hold(args)
      # type = bib, isbn
    end

    def cancel_hold(args)
      # type = bib, isbn 
    end

    def method_missing(name, *args, &block)
      service._parse name, *args
    end
    
  end

end
