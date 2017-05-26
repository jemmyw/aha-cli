module AhaCli
  module Models
    def for(path)
      AhaModel.for(path)
    end
    module_function :for

    class AhaModel
      class << self
        def for(path)
          path = path.to_s

          klass = (@@model_registry).detect do |cl|
            cl.path && cl.path.match(path)
          end || self

          klass
        end

        def inherited(mod)
          (@@model_registry ||= []) << mod
        end

        %w(path singular plural).each do |class_attr|
          define_method class_attr do |*args|
            if args.length == 1
              instance_variable_set("@#{class_attr}", args[0])
            else
              instance_variable_get("@#{class_attr}")
            end
          end
        end
      end

      %w(singular plural).each do |class_attr|
        define_method class_attr do
          self.class.public_send(class_attr)
        end
      end

      def initialize(attrs)
        @attrs = attrs
      end

      def [](name)
        @attrs[name.to_s]
      end

      def method_missing(name, *args, &block)
        self[name]
      end

      def to_h
        @attrs.dup
      end

      def ref
        id
      end

      def inspect
        "#{ref} #{name}"
      end
    end

    class Feature < AhaModel
      path %r{\bfeatures(/[^/]+)?}
      singular "feature"
      plural "features"

      def ref
        reference_num
      end
    end

    class Product < AhaModel
      path %{/products(/[^/]+)?}
      singular "product"
      plural "products"

      def ref
        reference_prefix
      end
    end
  end
end
