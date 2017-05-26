require "yaml"
require "openssl"
require_relative "terminal"

module AhaCli
  module Configuration
    class Encryptor
      def self.encrypt(value)
        return nil unless ENV["TERM_SESSION_ID"].to_s.length > 23
        des = OpenSSL::Cipher::Cipher.new("des-ede3-cbc")
        des.encrypt
        des.iv = iv = "01234567"
        des.key = ENV["TERM_SESSION_ID"]
        data = des.update(value) + des.final
        iv + data
      end

      def self.decrypt(value)
        return nil unless ENV["TERM_SESSION_ID"].to_s.length > 23
        des = OpenSSL::Cipher::Cipher.new("des-ede3-cbc")
        des.decrypt
        des.key = ENV["TERM_SESSION_ID"]
        des.iv = value.slice!(0, 8)
        decrypted = des.update(value) + des.final
        decrypted
      end
    end

    class ConfigFile
      include Terminal

      def initialize(file)
        @file = file
        self.load
      end

      def password
        return @password if @password
        encrypted_password = get("password")

        if encrypted_password
          Encryptor.decrypt(encrypted_password)
        else
          ask_password
        end
      rescue
        ask_password
      end

      def ask_password
        self.password = ask("Password?", echo: false)
      end

      def password=(new_password)
        set("password", Encryptor.encrypt(new_password))
        @password = new_password
      end

      def set(name, value)
        @config[name.to_s] = value
        flush
      end

      def get(name)
        @config[name.to_s]
      end

      def method_missing(name, *args, &block)
        if args.empty?
          get(name)
        elsif args.length == 1 && name.to_s =~ /(.+)=\z/
          set($1, args[0])
        else
          super
        end
      end

      def flush
        data = YAML.dump(@config)
        File.write(@file, data)
      end

      def load
        @config = begin
          if File.exists?(@file)
            data = File.read(@file)
            YAML.load(data)
          end
        rescue
          {}
        end
        @config = {} unless @config.is_a?(Hash)
      end

      def to_h
        @config.dup
      end

      def inspect
        @config.inspect
      end
    end

    def configuration
      location = options[:config] || begin
        if ENV["HOME"]
          File.join(ENV["HOME"], ".aha")
        else
          puts "I cannot find your home directory. Use --config to specify config location"
          exit 1
        end
      end

      @configuration ||= ConfigFile.new(location)
    end
  end
end

