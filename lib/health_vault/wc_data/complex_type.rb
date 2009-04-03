# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'rexml/document'

module HealthVault
  module WCData
    class ComplexType
      
      @@tag_names = {}
      @@child_params = {}
      @@child_methods = {}
      
      class << self
        
        def child_params
          @@child_params[self.name] ||= {}
        end
        
        def child_methods
          @@child_methods[self.name] ||= []
        end
      
        def set_tag_name(value)
          @@tag_names[self.name] = value
        end
        
        def tag_name
          @@tag_names[self.name]
        end
      
        def child(child_name, attrs = {})
          raise ArgumentError.new("Attributes are required") if attrs.empty?
        
          attrs = attrs.symbolize_keys
          attrs.assert_valid_keys(HealthVault::WCData::Child::PARAMS)
          
          child_params[child_name] = attrs
          
          define_child_accessors(child_name)

          if attrs[:max].to_i != 1 # Will be 0 if nil - we'll still want to go on
            define_child_multiple_accessors(child_name)
          end
        end
        
        HealthVault::WCData::Child::TYPES.each do |t|
          class_eval(%{
            def child_#{t}(name, attrs = {});
              attrs = attrs.symbolize_keys.merge(:type => '#{t}')
              child(name, attrs)
            end
          }, __FILE__, __LINE__)
        end
        
        def add_child_method(meth)
          child_methods << meth.to_s
        end
                
        private
        
          def define_child_accessors(name)
            method_name = name.to_s.underscore.strip
                        
            class_eval(%{
              def #{method_name}=(value, force = false)
                @children['#{name}'].send(:value=, value, force)
              end

              def #{method_name}
                @children['#{name}'].value
              end
            }, __FILE__, __LINE__)
            
            add_child_method(method_name)
          end
      
          def define_child_multiple_accessors(name)
            method_name = name.to_s.underscore.strip
            
            class_eval(%{
              def add_#{method_name}(value, force = false)
                @children['#{name}'].add_value(value, force)
              end

              def remove_#{method_name}(value)
                @children['#{name}'].remove_value(value)
              end
            }, __FILE__, __LINE__)
          end
        
      end
      
      include REXML
      
      def initialize(attrs = {})
        initialize_children
        self.attributes = attrs
        yield(self) if block_given?
      end
      
      def child_methods
        self.class.child_methods
      end
      
      def attributes=(attrs = {})
        attrs.each do |k,v|
          if child_methods.include?(k.to_s)
            self.__send__("#{k}=", v)
          else
            raise "Can't assign #{self.class} a value for #{k}"
          end
        end
      end
      
      def attributes
        self.class.child_methods.inject({}){|hsh, m| hsh[m] = self.__send__(m); hsh }
      end
      
      def tag_name
        self.class.tag_name
      end
      
      def required_elements
        query_elements.select(&:required?)
      end
      
      def optional_elements
        query_elements.reject(&:required?)
      end
      
      def query_elements
        result = []
        if block_given?
          @children.each do |key, value|
            if yield(value)
              result << key
            end
          end
        else
          result = @children.keys
        end
        return result        
      end

      # construct REXML::Element tree from children
      def element(container = nil)
        #cname = self.class.to_s
        my_name = tag_name.to_s.strip.downcase#cname.split('::')[-1].downcase#
        if container.nil?
          me = Element.new(my_name)
        elsif container.is_a?(String) || container.is_a?(Symbol) # Might as well support symbols too
          me = Element.new(container.to_s)
        else
          me = container
        end
        elements = @children.values.sort_by(&:order)
        elements.each do |el|
          val = el.value
          next if val.nil?
          if val.is_a?(Array)
            val.each do |v|
              sub_element(el.name, v, me)
            end
          else
            if el.place == :extension
              sub_element(el.name, val, me, false)
            elsif el.place == :attribute
              me.add_attribute(el.name, val.to_s)
            else
              sub_element(el.name, val, me)
            end
          end
        end
        return me
      end
      
      # parse WCData from the given xml element
      # TODO: Clean this up
      def parse_element(e)
        # parse elements
        e.elements.each do |child|
          node = child.name
          if @children[node].nil?
            begin
              unless @children['anything'].nil?
                #see if the parent is a 'thing'
                types = e.parent.get_elements('type-id')
                unless types.empty?
                  type_guid = types[0].text.to_s
                  type = WCData::Thing::Thing.guid_to_class(type_guid)
                  #add_new_to_children(@children['anything'].value, child, type)  
                  x = type.new
                  #TODO make SimpleTypes behave like their base types
                  #<HACK>
                  if x.is_a?(SimpleType) || x.is_a?(String)
                    x = child.text
                  end
                  #</HACK>
                  if x.respond_to?(:parse_element)
                    x.parse_element(child)
                  end
                  # TODO: Should we be setting this here?
                  @children['anything'].klass = type
                  if @children['anything'].value.is_a?(Array)
                    @children['anything'].add_value(x)
                  else
                    @children['anything'].value = x
                  end                
                end
              end
            rescue => err
              Configuration.instance.logger.error err
            end
            # unknown node type
            Configuration.instance.logger.debug "unknown node of #{node} for #{self.class.to_s}"
          else
            #add_new_to_children(@children[node].value,child, @children[node].klass)
            x = @children[node].klass.new
            #TODO make SimpleTypes behave like their base types
            #<HACK>
            if x.is_a?(SimpleType) || x.is_a?(String)
              x = child.text
            end
            #</HACK>
            if x.respond_to?(:parse_element)
              x.parse_element(child)
            end
            # TODO: Make this better
            if @children[node].value.is_a?(Array)
              @children[node].add_value(x)
            else
              @children[node].value = x
            end
          end
        end       
        # parse inner text
        if !@children['data'].nil? && !e.text.empty?
          @children['data'].value = e.text
        end
        # parse attributes
        e.attributes.each_attribute do |attr|
          name = attr.name
          if @children[name].nil?
            # unknown attribute type
            Configuration.instance.logger.debug "unknown attribute of #{name} for #{self.class.to_s}"
          else
            @children[name].value = attr.value.to_s
          end
        end
      end
      
      def add_new_to_children(target, node, klass)
        x = klass.new
        #TODO make SimpleTypes behave like their base types
        #<HACK>
        if x.is_a?(SimpleType) || x.is_a?(String)
          x = node.text
        end
        #</HACK>
        if x.respond_to?(:parse_element)
          x.parse_element(node)
        end
        if target.is_a?(Array)
          target << x
        else
          target = x
        end
      end
      
      def valid?
        valid = true
        choices = Hash.new
        @children.values.each do |child|
          if child.place == :element && child.has_choice?
            choices[child.choice] ||= false
            #TODO: validate choices
          elsif child.min > 1
            len = child.value.length
            valid = valid && (len > child.min)
            valid = valid && (len < child.max)
            child.value.each do |v|
              break if !valid
              begin
                if child.klass.superclass == ComplexType
                  valid = valid && v.valid?
                elsif child.klass.superclass == SimpleType
                  valid = valid && child.klass.valid?(v)
                else
                  valid = valid && !(v.nil? || v.to_s.empty?)
                end
              rescue => e
                Configuration.instance.logger.error e
                valid = false
                break
              end
            end
          elsif child.min == 1
            #TODO extract the checks to a seperate method
            begin
              child.valid?
            rescue => e
              Configuration.instance.logger.error e
              valid = false
              break
            end
          end          
        end
        return valid
      end
      
      # xml string
      def to_s
        return element.to_s
      end
      
      def method_missing(name, *args, &blk)
        #For more ease of use, forward method calls for
        #complexTypes that contain 'anything' nodes
        #to the 'anything', i.e. try to make 'anything' transparent
        unless @children['anything'].nil?
          #INFO: this will only work for single 'anythings'
          if @children['anything'].value.respond_to?(name)
            return @children['anything'].value.__send__(name, *args, &blk)            
          end          
        end
        super
      end

      private

        def sub_element(name, obj, parent, tag = true)
          if tag
            n = Element.new(name.to_s, parent)
            if obj.is_a?(ComplexType)
              obj.element(n)
            else
              n.text = obj.to_s
            end
          else
            if obj.is_a?(ComplexType)
              parent << obj.element
            else
              parent.text = obj.to_s
            end
          end
        end
        
        def child_params
          self.class.child_params
        end
        
        def initialize_children
          @children = HashWithIndifferentAccess.new
          
          child_params.each do |name, cp|
            child = HealthVault::WCData::Child.new(name, cp)
            @children[name] = child            
          end
        end
        
    end
  end
end
