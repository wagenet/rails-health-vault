module HealthVault
  module WCData
    class Child
      
      TYPES = %w(element attribute extension)
      PARAMS = [:class, :min, :max, :order, :place, :type, :choice]
      
      # Doesn't match above list on purpose
      attr_reader :name, :class_name, :min, :max, :order, :place, :choice
      
      def initialize(name, attributes = {})
        attributes = attributes.symbolize_keys
        attributes.assert_valid_keys(PARAMS)
                
        @name = name
        @class_name = attributes[:class].to_s
        @min = attributes[:min].to_i
        @max = attributes[:max].to_i > 0 ? attributes[:max].to_i : nil
        @order = attributes[:order].to_i
        @place = (attributes[:place] || attributes[:type]).to_sym
        @choice = attributes[:choice] && attributes[:choice].to_i
      end
      
      def [](key)
        ActiveSupport::Deprecation.warn("The [] accessor is deprecated")
        case key.to_sym
          when :class then klass
          when :type  then place
          else respond_to?(key) ? send(key) : nil
        end
      end
      
      def []=(key, value)
        ActiveSupport::Deprecation.warn("The []= setter is deprecated")
        respond_to?("#{key}=") ? 
          send("#{key}=", value) :
          raise("Can't set value for '#{key}'")
      end
      
      def type
        place
      end
      
      def anything?
        name == 'anything'
      end
      
      def singleton?
        max == 1
      end
      
      def has_choice?
        !choice.nil?
      end
      
      def required?
        min > 0
      end
      
      def klass
        @class_name.constantize
      end
      
      def class_name=(val)
        raise "Can only set the class on 'anything' elements" unless anything?
        @class_name = val.to_s
      end
      alias_method :klass=, :class_name=
      
      def value
        initialize_value unless @value_initialized
        @value
      end
      
      def value=(val, force = false)
        @value_initialized = true
        val = typecast_value(val) unless force
        @value = val
      end
      
      # Make new instance of klass but don't associate
      def build(attrs = {}, &block)
        klass.new(attrs, &block)
      end

      # Make new instance of klass and associate
      def create(attrs = {}, &block)
        self.add_value(build(attrs, &block))
      end
      
      # Note, this does not prevent value from being modified directly
      def add_value(val, force = false)
        if singleton?
          send(:value=, val, force)
        else
          val = typecast_value(val) unless force
          value << val
        end
        val
      end
      
      def remove_value(val)
        if singleton?
          self.value = nil if self.value == val
        else
          value.delete(val)
        end
        val
      end
      
      def to_s
        value.to_s
      end
      
      def valid?
        raise("Value required") if required? && value.nil?
        
        case klass.superclass
          when ComplexType
            raise("Not valid for #{value.class}") unless value.valid?
          when SimpleType
            raise("Not valid for #{klass}") unless klass.valid?(value)
          else
            raise("Value required") if value.to_s.empty?
        end
        
        # TODO: Validate numbers

        true
      end

      private
      
        # TODO: Can we make this more elegant?
        def typecast_value(val)
          return nil if val.nil?
          if val.is_a?(Array)
            val.map{|v| typecast_value(v) }
          else
            return klass.new(val) if klass.superclass == SimpleType
            return val            if val.is_a?(klass)
            return val.to_s       if val.is_a?(Numeric) || klass.is_a?(String)
            
            raise ArgumentError.new("Expected an instance of #{klass} got #{val.class}")
          end
        end
        
        def initialize_value
          unless @value_initialized
            @value_initialized = true
            self.value = singleton? ? ((required? && !has_choice?) ? klass.new : nil) : []
          end
        end

    end
  end
end