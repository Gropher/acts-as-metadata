module ActsAsMetadata
  def acts_as_metadata(options={})
    if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id$/
      scope = "#{options[:scope]}_id".to_sym
    else
		  scope = nil
		end
		
		MetadataType.class_variable_set("@@metadata_scope", scope)
		class_variable_set("@@metadata_scope", scope)
		class_eval do
      serialize :metadata_cache, JSON
      has_many :metadata, :as => :model, :dependent => :destroy, :class_name => "Metadata::Metadata"
      before_save :create_accessors_and_save_metadata
      validate :metadata_constraints

      def metadata_constraints
        metadata_types.each do |type_name|
          type = MetadataType.type(type_name, metadata_scope)
          value = get_metadata(type.tag)
          values = type.values.map {|v| v.is_a?(Array) ? v[1].to_s : v.to_s } rescue []
          if value.is_a? Array
            errors.add(type.tag, I18n.t('acts_as_metadata.errors.blank')) if type.mandatory && (value.blank? || value.map(&:blank?).reduce(:&))
            value.each_with_index do |v, i|
              errors.add("#{type.tag}_#{i}", I18n.t('acts_as_metadata.errors.format')) if values.blank? && type.format.present? && v.present? && v.to_s !~ Regexp.new("^#{type.format}$")
              errors.add("#{type.tag}_#{i}", I18n.t('acts_as_metadata.errors.values')) if values.present? && v.present? && !values.include?(v)
            end
          else
            errors.add(type.tag, I18n.t('acts_as_metadata.errors.blank')) if type.mandatory && value.blank?
            errors.add(type.tag, I18n.t('acts_as_metadata.errors.format')) if values.blank? && type.format.present? && value.present? && value.to_s !~ Regexp.new("^#{type.format}$")
            errors.add(type.tag, I18n.t('acts_as_metadata.errors.values')) if values.present? && value.present? && !values.include?(value.to_s)
          end
        end unless @skip_metadata_validation
      end

      def skip_metadata_validation!
        @skip_metadata_validation = true
      end

      
      def mass_assignment_authorizer(role = :default)
        super + metadata_types
      end
      
      def initialize(args=nil, options = {})
        scope = self.class.class_variable_get('@@metadata_scope') ? args[self.class.class_variable_get('@@metadata_scope')] : nil rescue nil
        types = MetadataType.model_types(model_name, scope)
        types.each do |type|
          create_accessor type
        end
        super
      end

      def update_attributes(attributes)
        create_accessors
        super
      end
      
      def attributes=(new_attributes)
        create_accessors
        assign_attributes(new_attributes, :without_protection => true)
      end
      
      def create_accessors
        metadata_types.each do |type|
          create_accessor type
        end 
      end

      def create_accessor type
        unless respond_to?(type) and respond_to?("#{type}=")
          #class_eval "attr_accessor :#{type}"
          class_eval "def #{type}; get_metadata('#{type}'); end"
          class_eval "def #{type}=(value); set_metadata('#{type}', value); end"
        end
      end

      def create_accessors_and_save_metadata
        create_accessors
        save_metadata
      end
      
      def method_missing(meth, *args, &block)
        begin
          super
        rescue NoMethodError
          name = meth.to_s
    	    if name =~ /^(.+)=$/
    	      name = name[0..-2]
    	      if metadata_types.include?(name)
    	        set_metadata(name, args.first)
    	      else
    	        raise
    	      end
    	    else
    	      if metadata_types.include?(name)
    	        get_metadata(name)
    	      else
    	        raise
    	      end
    	    end
    	  end
  	  end
  	  
      def metadata_scope
        self.class.class_variable_get('@@metadata_scope') ? self.send(self.class.class_variable_get('@@metadata_scope')) : nil
      end
  	  
  	  def model_name
  	    self.class.name.underscore.to_s
  	  end
      
      def metadata_type name
        MetadataType.type name, metadata_scope
      end

      def metadata_types
        MetadataType.model_types(model_name, metadata_scope)
      end

			def self.metadata_types scope=nil
				MetadataType.model_types(self.name.underscore.to_s, scope)
			end
      
      def get_metadata name
        load_metadata unless metadata_cache.is_a?(Hash)
        type = metadata_type name
				metadata_cache[name].blank? ? type.type_cast(type.default) : metadata_cache[name]
      end
      
      def set_metadata name, value
        type = metadata_type name
        raise NoMethodError if type.nil?
        load_metadata unless metadata_cache.is_a?(Hash)
        self.metadata_cache[name] = type.type_cast(value)
        self.metadata_cache[name] = [self.metadata_cache[name]].compact if type.multiple && !self.metadata_cache[name].is_a?(Array)
        self.metadata_cache[name] = type.type_cast(self.metadata_cache[name].first) if !type.multiple && self.metadata_cache[name].is_a?(Array)
      end

      def save_metadata
        Metadata::Metadata.delete_all(:model_type => self.class.name, :model_id => self.id) unless self.id.blank?
        self.metadata_types.each do |type_name|
          value = self.get_metadata(type_name)
          if value.is_a? Array
            value.each {|v| self.metadata.build(:metadata_type => type_name, :value => v) unless v.nil? }
          else
            self.metadata.build(:metadata_type => type_name, :value => value) unless value.nil?
          end
        end
      end

			def load_metadata
        hash = {}
				metadata.each do |m|
          if hash[m.metadata_type].nil?
            hash[m.metadata_type] = m.value
          elsif hash[m.metadata_type].is_a? Array
             hash[m.metadata_type] << m.value
          else
             hash[m.metadata_type] = [hash[m.metadata_type], m.value]
          end
        end
        self.metadata_cache = {}
        metadata_types.each {|type_name| set_metadata type_name, hash[type_name] }
      end
    end
  end
end
