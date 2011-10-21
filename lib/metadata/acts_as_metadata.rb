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
      has_many :metadata, :as => :model, :dependent => :destroy, :class_name => "Metadata::Metadata"
      before_create :create_accessors
      before_update :create_accessors
      
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
				self.metadata_cache[name]
      end
      
      def set_metadata(name, value)
        type = MetadataType.type(name, self.send(@@metadata_scope))
        value = value ? value : type.default
        self.metadata.where(:metadata_type => name).each{|m| m.destroy(true)}
        self.metadata.create({ :metadata_type => name, :value => value })
				self.update_metadata_cache
      end

			def update_metadata_cache
				self.metadata_cache = Hash[self.metadata.all.map { |m| [m.metadata_type, m.value] }]
			end          
    end
  end
end
