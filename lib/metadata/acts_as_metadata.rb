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

      
      def mass_assignment_authorizer
        super + metadata_types
      end
      
      def update_attributes(attributes)
        create_accessors
        super
      end
      
      def create_accessors
        metadata_types.each do |type|
          class_eval "attr_accessor :#{type}"
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
  	    self.class.name.underscore.to_sym
  	  end
      
      def metadata_types
        MetadataType.model_types(model_name, metadata_scope)
      end

			def self.metadata_types(scope=nil)
				types = MetadataType.model_types(self.name.underscore.to_sym, scope)
        return types
			end
      
      def get_metadata(name)
        load_metadata if !self.metadata_cache.is_a?(Hash)
        type = MetadataType.type(name, metadata_scope)
				type.type_cast(self.metadata_cache[name]) || type.default
      end
      
      def set_metadata(name, value)
        type = MetadataType.type(name, metadata_scope)
        raise NoMethodError if type.nil?
        load_metadata if !self.metadata_cache.is_a?(Hash)
        self.metadata_cache[name] = value || type.default
      end

      def save_metadata
        touch
        self.metadata.each{|m| m.destroy(true)}
        self.metadata_types.each do |type_name|
          value = self.get_metadata(type_name)
          self.metadata.build(:metadata_type => type_name, :value => value) unless value.nil?
        end
      end

			def load_metadata
				self.metadata_cache = Hash[self.metadata.all.map { |m| [m.metadata_type, m.value] }]
        self.save!
			end          
    end
  end
end
