require 'heroku-api'
require 'paratrooper/local_api_key_extractor'

module Paratrooper
  class HerokuWrapper
    attr_reader :api_key, :app_name, :heroku_api, :key_extractor

    def initialize(app_name, options = {})
      @app_name      = app_name
      @key_extractor = options[:key_extractor] || LocalApiKeyExtractor
      @api_key       = options[:api_key] || key_extractor.get_credentials
      @heroku_api    = options[:heroku_api] || Heroku::API.new(api_key: api_key)
    end

    def app_restart
      heroku_api.post_ps_restart(app_name)
    end

    def app_maintenance_off
      app_maintenance('0')
    end

    def app_maintenance_on
      app_maintenance('1')
    end

    def app_url
      app_domain_name
    end

    private
    def app_domain_name
      heroku_api.get_domains(app_name).body.last['domain']
    end

    def app_maintenance(flag)
      heroku_api.post_app_maintenance(app_name, flag)
    end
  end
end