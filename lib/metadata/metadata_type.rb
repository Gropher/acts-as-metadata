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
  before_save :set_correct_values
  after_create :refresh_metadata
  after_update :refresh_metadata
  before_destroy :refresh_metadata
  validates :tag, :presence => true, :format => {:with => /\A[a-z]+[a-z0-9_]*\Z/}
  validates :datatype, :presence => true
      
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
    return value.delete_if(&:blank?).map {|x| type_cast x } if value.is_a? Array
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
 
  def values= value
    value = value.invert.to_a if value.is_a?(Hash)
    super
  end
 
private 
  def drop_metadata_scheme_cache scope_column=nil, scope_value=nil
    Rails.cache.delete("metadata_scheme_#{scope_column}#{scope_value}_data")
    Rails.cache.delete("metadata_scheme_#{scope_column}#{scope_value}_types")
    Rails.cache.delete("metadata_scheme_#{scope_column}#{scope_value}_modeltypes")
  end

  def set_correct_values
		self.models = (models || []).map(&:to_sym).uniq.keep_if {|model| Kernel.const_defined?(model.capitalize) || model == :any }
		self.values = (values || []).uniq
    self.default = type_cast default
  end 

  def refresh_metadata
    drop_metadata_scheme_cache
    model_classes = models.include?(:any) ? ObjectSpace.each_object(Class).select {|klass| klass < ActiveRecord::Base } : models.map {|model| Kernel.const_get model }
    scope_columns = []
    model_classes.each do |model|
      model
      scope_columns << model.metadata_scope if model.respond_to? :metadata_scope
    end
    scope_columns.uniq.compact.each do |scope_column|
      drop_metadata_scheme_cache scope_column, send(scope_column)
    end
  end
end
