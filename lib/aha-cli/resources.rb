require_relative "models"

module AhaCli
  module Resources
    Pagination = Struct.new(:total_records, :total_pages, :current_page)

    class AhaResult
      def initialize(resource, response)
        @resource = resource
        @response = response
        @model = Models.for(resource.path)
      end

      def success?
        @response.success?
      end

      def status
        @response.status
      end

      def body
        @response.body
      end

      def inspect
        body.inspect
      end
    end

    class AhaIndexResult < AhaResult
      def body
        @response.body[@model.plural].map(&@model.method(:new))
      end

      def pagination
        @pagination ||= Pagination.new(*@response.body["pagination"].values)
      end

      def inspect
        "[\n" +
          body.map(&:inspect).map{|i| "  " + i }.join("\n") +
          "\n],\ntotal_records = #{pagination.total_records}\ntotal_pages = #{pagination.total_pages}"
      end
    end

    class AhaResourceResult < AhaResult
      def body
        @model.new(@response.body[@model.singular])
      end
    end

    class AhaCommandResult < AhaResult
    end

    class AhaPutResult < AhaCommandResult
      def inspect
        if success?
          "Updated #{@resource.path}"
        else
          "Failed to update #{@resource.path}"
        end
      end
    end

    class AhaResource
      attr_reader :path

      def self.for(path, client)
        new(path.to_s, client)
      end

      def initialize(path, client)
        @path = path.to_s
        @client = client
      end

      def method_missing(name, *args, &block)
        if args.length == 0
          self.class.for(File.join(@path, name.to_s), @client)
        else
          super
        end
      end

      def [](name)
        self.class.for(File.join(@path, name), @client)
      end

      def index(fields: nil)
        AhaIndexResult.new(self, @client.get(@path))
      end

      def get(id, fields: nil)
        params = {}
        params[:fields] = fields if fields

        AhaResourceResult.new(
          self,
          @client.get(File.join(@path, id), params)
        )
      end

      def put(id, body)
        AhaPutResult.new(
          self,
          @client.put(
            File.join(@path, id)
          ) do |put|
            put.body = JSON.dump(body.to_h)
          end
        )
      end

      def post(body)
        AhaCommandResult.new(
          self,
          @client.post(
            @path
          ) do |post|
            post.body = body.to_h
          end
        )
      end

      def delete(id)
        AhaCommandResult.new(
          self,
          @client.delete(
            File.join(@path, id)
          )
        )
      end
    end
  end
end

