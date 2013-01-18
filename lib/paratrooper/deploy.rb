require 'heroku-api'
require 'paratrooper/default_formatter'

module Paratrooper
  class Deploy
    attr_reader :app_name, :formatter, :heroku, :tag_name

    def initialize(app_name, options = {})
      @app_name  = app_name
      @formatter = options[:formatter] || DefaultFormatter.new
      @heroku    = options[:heroku_auth] || Heroku::API.new(api_key: ENV['HEROKU_API_KEY'])
      @tag_name  = options[:tag]
    end

    def activate_maintenance_mode
      notify_screen("Activating Maintenance Mode")
      app_maintenance_on
    end

    def deactivate_maintenance_mode
      notify_screen("Deactivating Maintenance Mode")
      app_maintenance_off
    end

    def update_repo_tag
      unless tag_name.empty?
        notify_screen("Updating Repo Tag: #{tag_name}")
        system "git tag #{tag_name} -f"
        system "git push origin #{tag_name}"
      end
    end

    def push_repo(branch = 'master')
      notify_screen("Pushing #{branch} to Heroku")
      system "git push -f #{git_remote} #{branch}"
    end

    def run_migrations
      notify_screen("Running database migrations")
      system "heroku run rake db:migrate --app #{app_name}"
    end

    def app_restart
      heroku.post_ps_restart(app_name)
    end

    def warm_instance(wait_time = 5)
      sleep wait_time
      notify_screen("Accessing #{app_url} to warm up your application")
      system "curl -Il http://#{app_url}"
    end

    def default_deploy
      activate_maintenance_mode
      update_repo_tag
      push_repo
      run_migrations
      app_restart
      deactivate_maintenance_mode
      warm_instance
    end
    alias_method :deploy, :default_deploy

    private
    def _app_maintenance(flag)
      heroku.post_app_maintenance(app_name, flag)
    end

    def app_maintenance_off
      _app_maintenance('0')
    end

    def app_maintenance_on
      _app_maintenance('1')
    end

    def app_url
      heroku.get_domains(app_name).body.last['domain']
    end

    def git_remote
      "git@heroku.com:#{app_name}.git"
    end

    def notify_screen(message)
      formatter.puts(message)
    end
  end
end