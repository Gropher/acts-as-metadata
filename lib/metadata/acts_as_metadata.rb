module ActsAsMetadata
  def acts_as_metadata(options)
		model = options[:model]
    if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id$/
      scope = "#{options[:scope]}_id".to_sym
    else
		  scope = nil
		end
		
		MetadataType.class_eval "@metadata_scope = :#{scope}"
		class_eval "@@metadata_scope = :#{scope}"
    class_eval "@@metadata_model = :#{model}"
		class_eval do
      has_many :metadata, :as => :model, :dependent => :destroy, :class_name => "Metadata::Metadata"
      
      def metadata_types
        types = MetadataType.model_types(@@metadata_model.to_sym, self.send(@@metadata_scope))
        #types = types.map{|t| MetadataType.type(t).send(@@metadata_scope) == self.send(@@metadata_scope) ? t : nil}.compact if @@metadata_scope
        return types
      end

			def self.metadata_types(scope=nil)
				types = MetadataType.model_types(@@metadata_model, scope)
        #types = types.map{|t| MetadataType.type(t).send(@@metadata_scope) == scope.id ? t : nil}.compact if @@metadata_scope
        return types
			end
      
      def get_metadata(name)
				self.metadata_hash[name]
      end
      
      def set_metadata(name, value)
        type = MetadataType.type(name, self.send(@@metadata_scope))
        value = value ? value : type.default
        self.metadata.where(:metadata_type => name).each{|m| m.detroy(true)}
        self.metadata.create({:metadata_type => name, :value => value})
				Rails.cache.delete("metadata_#{@@metadata_model}_#{self.id}")
      end

			def metadata_hash
			  Rails.cache.fetch("metadata_#{@@metadata_model}_#{self.id}", :expires_in => 60.minutes) do
				  Hash[self.metadata.all.map { |m| [m.metadata_type, m.value] }]
				end
			end          
    end
    MetadataType.model_types(model).each do |name|
      type = MetadataType.type(name)
      #if type.mandatory
      #  class_eval "validates :#{name}, :presence => true"  
      #end
      class_eval "attr_accessor :#{name}"
      class_eval "attr_accessible :#{name}"
      class_eval "def #{name}\n get_metadata(\"#{name}\") \nend"
      class_eval "def #{name}=(value)\n set_metadata(\"#{name}\", value) \nend"  
    end
  end
end
