require "thor"
require "yaml"
require "byebug"

require_relative "aha-cli/terminal"
require_relative "aha-cli/configuration"
require_relative "aha-cli/resources"
require_relative "aha-cli/commands"
require_relative "aha-cli/client"
require_relative "aha-cli/cli-client"

module AhaCli
  class CLI < Thor
    include Terminal
    include Configuration
    include CliClient

    def initialize(*args)
      super(args[0], args[1], {moose: true})
    end

    desc "login [subdomain] [email]", "Log-in to Aha!"
    def login(subdomain = nil, email = nil)
      subdomain ||= ask("Subdomain?")
      email ||= ask("Username?")
      password = ask("Password?", echo: false)

      puts "Verifying #{email}..."
      client = AhaClient.new(subdomain, url: client_url)

      begin
        client.login(email, password)
        me = client.get("me")
        puts "Successfully logged in as user #{me["id"]}"

        configuration.subdomain = subdomain
        configuration.email = email
        configuration.password = password
      rescue => error
        puts "Could not login: #{error}"
        puts error.backtrace.join("\n")
      end
    end

    [
      %w(product products Product),
      %w(release releases Release),
      %w(feature features Feature)
    ].each do |(s, p, k)|
      desc "#{s} SUBCOMMAND ...ARGS", "manage #{p}"
      subcommand s, Commands.const_get(k)
    end

    desc "config SUBCOMMAND ...ARGS", "manage client configuratin"
    subcommand "config", Commands::Config
  end
end