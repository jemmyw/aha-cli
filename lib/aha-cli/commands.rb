require "thor"
require_relative "configuration"
require_relative "cli-client"
require_relative "models"

module AhaCli
  module Commands
    class Command < Thor
      include Configuration
      include CliClient

      private

      def product
        options[:product] || configuration.product
      end
    end

    def ModelCommand(model)
      Class.new(Command) do
        desc "ls", "List #{model}"
        define_method(:ls) do
          puts client[model].index.inspect
        end

        desc "get ref", "Get #{model} with reference or id"
        define_method(:get) do |id|
          puts client[model].get(id).inspect
        end

        desc "update ref [field=value]", "Update #{model} with id"
        long_desc <<DESC
Update a model by calling update:

  update DEMO-20 name=New feature name
DESC
        define_method(:update) do |id, *args|
          fields = Hash[args.reduce([]) do |acc, arg|
            if arg.include?("=")
              field, head = arg.split("=")
              acc + [[field, head]]
            else
              field, head = acc.last
              acc[0..-2] + [[field, "#{head} #{arg}"]]
            end
          end]

          model_class = Models.for(client[model].path)
          result = client[model].put(id, {
            model_class.singular => fields
          })

          if result.success?
            puts "Updated #{model_class.singular} #{id}"
          else
            puts "Failed to update #{model_class.singular} #{id}"
          end
        end
      end
    end
    module_function :ModelCommand

    class Feature < ModelCommand("features")
      class_option :product, type: :string
      class_option :release, type: :string
    end

    class Release < ModelCommand("releases")
      class_option :product, type: :string
    end

    class Product < ModelCommand("products")
      desc "set PROD-1", "Set the current product"
      def set(id)
        configuration.set("product", id)
        puts "Set product to #{id}"
      end
    end

    class Config < Command
      desc "set KEY VALUE", "Set a key value"
      def set(key, value)
        configuration.set(key, value)
        puts "#{key} set to #{value}"
      end

      desc "get KEY", "Get a key value"
      def get(key)
        puts "#{key} = #{configuration.get(key)}"
      end

      desc "ls", "List values"
      def ls
        configuration.to_h.each do |key, value|
          puts "#{key} = #{value}"
        end
      end
    end
  end
end
