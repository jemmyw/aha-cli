require "addressable/uri"
require "faraday"
require "faraday_middleware"
require_relative "resources"

module AhaCli
  class AhaClient
    def initialize(subdomain, options = {})
      @base_url = options[:url] || "https://aha.io"
      @subdomain = subdomain

      @url = Addressable::URI.parse(@base_url).tap do |uri|
        uri.host = [subdomain, uri.host].join(".")
      end

      @conn = Faraday.new(url: File.join(@url.to_s, "/api/v1")) do |conn|
        conn.request :json
        conn.response :json, :content_type => /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    def login(email, password)
      @conn.basic_auth(email, password)
    end

    %w(get post put delete request).each do |m|
      define_method m do |*args, &block|
        @conn.public_send(m, *args, &block)
      end
    end

    def [](name)
      Resources::AhaResource.for(name.to_s, self)
    end

    def method_missing(name, *args)
      if args.any?
        self[name].get(*args)
      else
        self[name]
      end
    end
  end
end
