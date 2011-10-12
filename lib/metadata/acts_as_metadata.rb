module ActsAsMetadata
  def acts_as_metadata(options)
		model = options[:model]
    if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id$/
      scope = "#{options[:scope]}_id".to_sym
    else
		  scope = nil
		end
		
		MetadataType.instance_variable_set("@metadata_scope", scope)
		class_eval "@@metadata_scope = :#{scope}"
    class_eval "@@metadata_model = :#{model}"
		class_eval do
      has_many :metadata, :as => :model, :dependent => :destroy, :class_name => "Metadata::Metadata"
      
      def method_missing(meth, *args, &block)
        type_names = MetadataType.model_types()
  	    if meth.to_s =~ /^(.+)=$/
  	      meth = meth[0..-2]
  	      if type_names.include?(meth)
  	        set_metadata(meth, args.first)
  	      else
  	        super
  	      end
  	    else
  	      if type_names.include?(meth)
  	        get_metadata(meth)
  	      else
  	        super
  	      end
  	    end
  	  end
      
      def metadata_types
        MetadataType.model_types(@@metadata_model.to_sym, self.send(@@metadata_scope))
      end

			def self.metadata_types(scope=nil)
				types = MetadataType.model_types(@@metadata_model, scope)
        return types
			end
      
      def get_metadata(name)
				self.metadata_hash[name]
      end
      
      def set_metadata(name, value)
        type = MetadataType.type(name, self.send(@@metadata_scope))
        value = value ? value : type.default
        self.metadata.where(:metadata_type => name).each{|m| m.destroy(true)}
        self.metadata.create({ :metadata_type => name, :value => value })
				Rails.cache.delete("metadata_#{@@metadata_model}_#{self.id}")
      end

			def metadata_hash
			  Rails.cache.fetch("metadata_#{@@metadata_model}_#{self.id}", :expires_in => 60.minutes) do
				  Hash[self.metadata.all.map { |m| [m.metadata_type, m.value] }]
				end
			end          
    end
  end
end
