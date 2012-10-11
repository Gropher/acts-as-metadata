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
      serialize :metadata_cache
      has_many :metadata, :as => :model, :dependent => :destroy, :class_name => "Metadata::Metadata"
      before_create :create_accessors_and_save_metadata
      before_update :create_accessors_and_save_metadata
      validate :metadata_constraints

      def metadata_constraints
        metadata_types.each do |type_name|
          type = MetadataType.type(type_name, metadata_scope)
          value = get_metadata(type.tag)
          values = type.values.map {|v| v.is_a?(Array) ? v[1] : v } rescue []
          errors.add(type.tag, I18n.t('acts_as_metadata.errors.blank')) if type.mandatory && value.blank?
          errors.add(type.tag, I18n.t('acts_as_metadata.errors.format')) if !type.format.blank? && !value.blank? && value.to_s !~ Regexp.new("^#{type.format}$")
          errors.add(type.tag, I18n.t('acts_as_metadata.errors.values')) if !values.blank? && !value.blank? && !values.include?(value)
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
      
      def create_accessors
        metadata_types.each do |type|
          create_accessor type
        end 
      end

      def create_accessor type
        class_eval "attr_accessor :#{type}"
        class_eval "def #{type}; get_metadata('#{type}'); end"
        class_eval "def #{type}=(value); set_metadata('#{type}', value); end"
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
  	    self.class.name.underscore.to_sym
  	  end
      
      def metadata_types
        MetadataType.model_types(model_name, metadata_scope)
      end

			def self.metadata_types(scope=nil)
				MetadataType.model_types(self.name.underscore.to_sym, scope)
			end
      
      def get_metadata(name)
        load_metadata unless metadata_cache.is_a?(Hash)
				metadata_cache[name]
      end
      
      def set_metadata(name, value)
        type = MetadataType.type(name, metadata_scope)
        raise NoMethodError if type.nil?
        load_metadata unless metadata_cache.is_a?(Hash)
        self.metadata_cache[name] = type.type_cast(value) || type.type_cast(type.default)
      end

      def save_metadata
        Metadata::Metadata.delete_all(:model_type => self.class.name, :model_id => self.id) unless self.id.blank?
        self.metadata_types.each do |type_name|
          value = self.get_metadata(type_name)
          self.metadata.build(:metadata_type => type_name, :value => value) unless value.nil?
        end
      end

			def load_metadata
				self.metadata_cache = Hash[self.metadata.all.map { |m| [m.metadata_type, m.value] }]
			end          
    end
  end
end
