module ActsAsMetadata
  def acts_as_metadata options={}
    if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id$/
      @metadata_scope = "#{options[:scope]}_id".to_sym
    else
		  @metadata_scope = nil
		end
	  	
		class_eval do
      serialize :metadata_cache
      has_many :metadata, :as => :model, :dependent => :destroy, :class_name => "Metadata::Metadata", autosave: true
      after_initialize :create_accessors
      before_save :save_metadata
      validate :metadata_constraints

      def metadata_constraints
        metadata_types.each do |type_name|
          type = metadata_type type_name
          value = get_metadata(type.tag)
          values = type.values.map {|v| v.is_a?(Array) ? v[1].to_s : v.to_s } rescue []
          if value.is_a? Array
            errors.add(type.tag, I18n.t('acts_as_metadata.errors.blank')) if type.mandatory && (value.blank? || value.map(&:blank?).reduce(:&))
            value.each_with_index do |v, i|
              errors.add("m_#{type.tag}_#{i}", I18n.t('acts_as_metadata.errors.format')) if values.blank? && type.format.present? && v.present? && v.to_s !~ Regexp.new("^#{type.format}$")
              errors.add("m_#{type.tag}_#{i}", I18n.t('acts_as_metadata.errors.values')) if values.present? && v.present? && !values.include?(v)
            end
          else
            errors.add("m_#{type.tag}", I18n.t('acts_as_metadata.errors.blank')) if type.mandatory && value.blank?
            errors.add("m_#{type.tag}", I18n.t('acts_as_metadata.errors.format')) if values.blank? && type.format.present? && value.present? && value.to_s !~ Regexp.new("^#{type.format}$")
            errors.add("m_#{type.tag}", I18n.t('acts_as_metadata.errors.values')) if values.present? && value.present? && !values.include?(value.to_s)
          end
        end unless @skip_metadata_validation
      end

      def skip_metadata_validation!
        @skip_metadata_validation = true
      end
      
      def mass_assignment_authorizer role = :default
        super + metadata_types.map {|t| "m_#{t}"}
      end
      
      def create_accessors
        metadata_types.each do |type|
          create_accessor type
        end 
      end

      def create_accessor type
        class_eval "attr_accessor :m_#{type}"
        class_eval "def m_#{type}; get_metadata('#{type}'); end"
        class_eval "def m_#{type}=(value); set_metadata('#{type}', value); end"
      end
  	  
      def metadata_scope
        self.class.metadata_scope
      end
  	  
      def self.metadata_scope
        @metadata_scope
      end
  	  
      def metadata_type name
        self.class.metadata_scheme(metadata_scope)[name]
      end

      def metadata_types
        self.class.metadata_types metadata_scope
      end

			def self.metadata_types scope=nil
        model = name.underscore.to_sym
        types = Rails.cache.fetch("metadata_scheme_#{metadata_scope}#{scope}_modeltypes", expires_in: 60.minutes) do
           res = { :any => [] }
           metadata_scheme(scope).each do |tag, type|
             type.models.each do |model| 
               res[model] = [] if res[model].blank?
               res[model] << tag
             end if type.models
           end
           res
        end
        types[model] ? (types[model] | types[:any]).uniq : types[:any]
			end
       
      def self.metadata_scheme_data(scope=nil)
        Rails.cache.fetch("metadata_scheme_#{metadata_scope}#{scope}_data", expires_in: 60.minutes) do
          uncached do
            scope.blank? ? MetadataType.all : MetadataType.where(metadata_scope => scope).all
          end
        end
      end
      
      def self.metadata_scheme(scope=nil)
        Rails.cache.fetch("metadata_scheme_#{metadata_scope}#{scope}_types", expires_in: 60.minutes) do
          res = {}
          metadata_scheme_data(scope).each do |type|
            res[type.tag] = type
          end
          res
        end
      end

      def get_metadata name
        load_metadata unless metadata_cache.is_a? Hash
        type = metadata_type name
				metadata_cache[name].blank? ? type.type_cast(type.default) : metadata_cache[name]
      end
      
      def set_metadata name, value
        type = metadata_type name
        raise NoMethodError if type.nil?
        load_metadata unless metadata_cache.is_a? Hash
        metadata_cache[name] = type.type_cast(value)
        metadata_cache[name] = [metadata_cache[name]].compact if type.multiple && !metadata_cache[name].is_a?(Array)
        metadata_cache[name] = type.type_cast(metadata_cache[name].first) if !type.multiple && metadata_cache[name].is_a?(Array)
      end

      def save_metadata
        metadata.map &:mark_for_destruction
        metadata_types.each do |type_name|
          value = get_metadata(type_name)
          if value.is_a? Array
            value.each {|v| metadata.build(metadata_type: type_name, value: v) unless v.nil? }
          else
            metadata.build(metadata_type: type_name, value: value) unless value.nil?
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
