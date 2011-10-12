class MetadataType < ActiveRecord::Base
  DATATYPES = {
    :string => "string",
    :text => "text",
    :date => "date",
    :datetime => "datetime",
    :number => "number",
    :boolean => "boolean",
    :array => "array"
  }

  serialize :default
  serialize :values
  serialize :models
  after_create :set_default_values
  after_update :drop_cache
  before_destroy :drop_cache
	attr_accessor :models_json, :values_json, :default_json
  attr_accessible  :tag, :name, :description, :models, :mandatory, :default, :format, :datatype, :values, :models_json, :values_json, :default_json
  validates :tag, :presence => true, :uniqueness => true, :format => {:with => /[a-z]+/}
  #validates :datatype, :presence => true
  default_scope :conditions => {:deleted_at => nil}, :order => 'created_at DESC'
      
  def self.default
    self.new({
      :tag => :sample,
      :name => "Sample",
      :models => [:any],
      :mandatory => false,
      :default => nil,
      :datatype => "string",
      :format => nil,
      :values => nil
    })
  end
  
#  def destroy
#    self.run_callbacks(:destroy)
#    self.update_attribute(:deleted_at, Time.now.utc)
#  end
 
	def models_json
		self.models ? self.models.to_json : [].to_json
	end

	def models_json=(value)
		self.models = JSON.parse(value) rescue []
	end 

	def values_json
    self.values ? self.values.to_json : [].to_json
  end

  def values_json=(value)
    self.values = JSON.parse(value) rescue []
  end

	def default_json
    self.default.is_a?(String) ? self.default : self.default.to_json
  end

  def default_json=(value)
    self.default = JSON.parse(value) rescue value
  end

  def self.scheme
    load_scheme
    @types
  end
  
  def self.model_types(model)
    load_scheme
    @model_types[model] ? (@model_types[model] | @model_types[:any]).uniq : @model_types[:any]
  end
  
  def self.type(name)
    load_scheme
    @types[name]
  end
  
  def self.scheme=(value)
    @scheme = value
    @types = {}
    @model_types = {:any => []}
    @scheme.each do |type| 
      @types[type.tag] = type
    	type.models.each do |model| 
      	@model_types[model] = [] if !@model_types[model]
      	@model_types[model] << type.tag
     	end if type.models
    end
  end
  
  def self.load_scheme
    reload_scheme if !@scheme 
  end
  
  def self.reload_scheme
		uncached do
      scheme_data = self.all
      if scheme_data.count > 0
        self.scheme = scheme_data
      else
        self.scheme = []#self.default.save
      end
    end
  end
 
  def self.drop_cache_and_reload
    MetadataType.reload_scheme
    Dir[File.join(Rails.root, "app", "models", "*.rb")].each do |f|
      load f
    end
  end
 
private 
  def set_default_values
		self.models = [] if self.models.nil?
		self.values = [] if self.values.nil?
		self.save
		MetadataType.drop_cache_and_reload
	end 

   def drop_cache
     MetadataType.drop_cache_and_reload
   end
end
