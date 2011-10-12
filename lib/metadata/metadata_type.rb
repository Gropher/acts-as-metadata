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
  validates :tag, :presence => true, :format => {:with => /[a-z]+/}
  validates :datatype, :presence => true
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


  def self.scheme_data(scope=nil)
    Rails.cache.fetch("metadata_scheme_#{@metadata_scope}#{scope}_data", :expires_in => 60.minutes) do
		  uncached do
        scheme_data = scope.blank? ? self.all : self.where(@metadata_scope => scope).all
        if scheme_data.count > 0
          scheme_data
        else
           []
        end
      end
		end
  end
  
  def self.scheme(scope=nil)
    Rails.cache.fetch("metadata_scheme_#{@metadata_scope}#{scope}_types", :expires_in => 60.minutes) do
      res = {}
      self.scheme_data(scope).each do |type|
        res[type.tag] = type
      end
      res
    end
  end
  
  def self.model_types(model, scope=nil)
    model_types = Rails.cache.fetch("metadata_scheme_#{@metadata_scope}#{scope}_modeltypes", :expires_in => 60.minutes) do
       res = {:any => []}
       self.scheme(scope).each do |tag, type|
         type['models'].each do |model| 
      	   res[model] = [] if !res[model]
      	   res[model] << tag
     	   end if type['models'] 
     	 end
     	 res
    end
    model_types[model] ? (model_types[model] | model_types[:any]).uniq : model_types[:any]
  end
  
  def self.type(name, scope=nil)
    self.schenme(scope)[name]
  end
 
  def self.drop_cache_and_reload(scope=nil)
    Rails.cache.delete("metadata_scheme_#{@metadata_scope}#{scope}_data")
    Rails.cache.delete("metadata_scheme_#{@metadata_scope}#{scope}_types")
    Rails.cache.delete("metadata_scheme_#{@metadata_scope}#{scope}_modeltypes")
    Dir[File.join(Rails.root, "app", "models", "*.rb")].each do |f|
      load f
    end
  end
 
private 
  def set_default_values
		self.models = [] if self.models.nil?
		self.values = [] if self.values.nil?
		self.save
		if @metadata_scope
		  MetadataType.drop_cache_and_reload(self.send(@metadata_scope))
		else
		  MetadataType.drop_cache_and_reload
		end  
	end 

  def drop_cache
    if @metadata_scope
      MetadataType.drop_cache_and_reload(self.send(@metadata_scope))
    else
      MetadataType.drop_cache_and_reload
    end
  end
end
