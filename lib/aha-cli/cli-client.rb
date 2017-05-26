module AhaCli
  module CliClient
    def self.included(mod)
      mod.send :class_option, :url, type: :string
    end

    protected

    def logged_in?
      configuration.email && configuration.subdomain
    end

    def client_url
      options[:url] || configuration.url || "https://aha.io"
    end

    def client
      @client ||= begin
        unless logged_in?
          puts <<-ERR
You must login first:

  aha login
          ERR

          exit 1
        end

        client = AhaClient.new(configuration.subdomain, url: client_url)
        client.login(configuration.email, configuration.password)
        client
      end
    end
  end
end
