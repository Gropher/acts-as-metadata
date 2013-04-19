class MetadataType < ActiveRecord::Base  
  DATATYPES = {
    :string => "string",
    :text => "text",
    :date => "date",
    :datetime => "datetime",
    :number => "number",
    :boolean => "boolean",
    :array => 'array'
  }

  serialize :default
  serialize :values
  serialize :models
  after_create :set_default_values
  after_update :refresh_metadata
  before_destroy :refresh_metadata
	attr_accessor :models_json, :values_json, :default_json
  attr_accessible  :tag, :name, :description, :models, :mandatory, 
    :default, :format, :datatype, :values, :multiple,
    :models_json, :values_json, :default_json
  validates :tag, :presence => true, :format => {:with => /^[a-z]+[a-z0-9_]*$/},
    :exclusion => { :in => %w(format errors callback action categorie accept attributes host key layout notify open render save template type id parent_id lft rgt test select),
     :message => "this name is reserved"}
  validates :datatype, :presence => true
  default_scope :conditions => {:deleted_at => nil}, :order => 'created_at DESC'
      
  def self.default
    self.new({
      :tag => :sample,
      :name => "Sample",
      :models => [:any],
      :mandatory => false,
      :multiple => false,
      :default => 'default',
      :datatype => "string",
      :format => nil,
      :values => nil
    })
  end

  def type_cast(value)
    return value.map {|x| type_cast x } if value.is_a? Array
    return nil if value.nil? && datatype != 'boolean'
    return value unless value.is_a?(String) || value.nil?

    case datatype
    when 'date' 
      ActiveRecord::ConnectionAdapters::Column.string_to_date value
    when 'datetime'
      ActiveRecord::ConnectionAdapters::Column.string_to_time value
    when 'number'
      Integer value
    when 'boolean'
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean value
    else
      value
    end rescue nil
  end
 
	def models_json
		self.models ? self.models.to_json : [].to_json
	end

	def models_json=(value)
		self.models = JSON.parse(value) rescue []
	end 

  def values= value
    value =  value.invert.to_a if value.is_a?(Hash)
    super
  end

	def values_json
    self.values ? self.values.to_a.to_json : [].to_json
  end

  def values_json=(value)
    self.values = JSON.parse(value) rescue []
    values.each {|v| v.is_a?(Array) ? v.each(&:strip!) : v.strip! } if values.is_a? Array
  end

  def default
    type_cast(attributes['default'])
  end

	def default_json
    self.default.to_json
  end

  def default_json=(value)
    self.default = JSON.parse(value) rescue value[/"(.*)"/, 1]
  end

  def self.scheme_data(scope=nil)
    Rails.cache.fetch("metadata_scheme_#{@@metadata_scope}#{scope}_data", :expires_in => 60.minutes) do
		  uncached do
        scheme_data = scope.blank? ? self.all : self.where(@@metadata_scope => scope).all
        if scheme_data.count > 0
          scheme_data
        else
          []
        end
      end
		end
  end
  
  def self.scheme(scope=nil)
    Rails.cache.fetch("metadata_scheme_#{@@metadata_scope}#{scope}_types", :expires_in => 60.minutes) do
      res = {}
      self.scheme_data(scope).each do |type|
        res[type.tag] = type
      end
      res
    end
  end
  
  def self.model_types(model, scope=nil)
    types = Rails.cache.fetch("metadata_scheme_#{@@metadata_scope}#{scope}_modeltypes", :expires_in => 60.minutes) do
       res = { :any => [] }
       self.scheme(scope).each do |tag, type|
         type.models.each do |model| 
      	   res[model] = [] if res[model].blank?
      	   res[model] << tag
     	   end if type.models
     	 end
     	 res
    end
    types[model] ? (types[model] | types[:any]).uniq : types[:any]
  end
  
  def self.type(name, scope=nil)
    self.scheme(scope)[name]
  end
 
  def self.drop_cache(scope=nil)
    Rails.cache.delete("metadata_scheme_#{@@metadata_scope}#{scope}_data")
    Rails.cache.delete("metadata_scheme_#{@@metadata_scope}#{scope}_types")
    Rails.cache.delete("metadata_scheme_#{@@metadata_scope}#{scope}_modeltypes")
  end
 
private 
  def set_default_values
		self.models = [] if self.models.nil?
		self.values = [] if self.values.nil?
		self.save
		if @@metadata_scope
		  MetadataType.drop_cache(self.send(@@metadata_scope))
		else
		  MetadataType.drop_cache
		end  
	end 

  def refresh_metadata
    if @@metadata_scope
      MetadataType.drop_cache(self.send(@@metadata_scope))
    else
      MetadataType.drop_cache
    end
  end
end
