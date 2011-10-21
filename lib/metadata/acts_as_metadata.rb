module ActsAsMetadata
  def acts_as_metadata(options)
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
      
      def create_accessors_and_save_metadata
        metadata_types.each do |type|
          class_eval "attr_accessor :#{type}"
          class_eval "def #{type}; get_metadata('#{type}'); end"
          class_eval "def #{type}=(value); set_metadata('#{type}', value); end"
        end
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
  	  
  	  def model_name
  	    self.class.name.underscore.to_sym
  	  end
      
      def metadata_types
        MetadataType.model_types(model_name, self.send(@@metadata_scope))
      end

			def self.metadata_types(scope=nil)
				types = MetadataType.model_types(self.name.underscore.to_sym, scope)
        return types
			end
      
      def get_metadata(name)
        load_metadata if !self.metadata_cache.is_a?(Hash)
				self.metadata_cache[name]
      end
      
      def set_metadata(name, value)
        type = MetadataType.type(name, self.send(@@metadata_scope))
        raise NoMethodError if type.nil?
        load_metadata if !self.metadata_cache.is_a?(Hash)
        self.metadata_cache[name] = value ? value : type.default
      end

      def save_metadata
        self.metadata.each{|m| m.destroy(true)}
        self.metadata_cache.each do |name, value|
          self.metadata.create({ :metadata_type => name, :value => value })
        end if self.metadata_cache.is_a?(Hash)
      end

			def load_metadata
				self.metadata_cache = Hash[self.metadata.all.map { |m| [m.metadata_type, m.value] }]
        self.save
			end          
    end
  end
end
