require 'spec_helper'

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'my_models'")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'metadata'")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'metadata_types'")
ActiveRecord::Base.connection.create_table(:my_models) do |t|
  t.integer :id
  t.string :name
  t.text :description
  t.text :metadata_cache
  t.datetime "created_at"
  t.datetime "updated_at"
end
ActiveRecord::Base.connection.create_table(:metadata) do |t|
  t.string   "metadata_type"
  t.integer  "model_id"
  t.string   "model_type"
  t.text     "value"
  t.datetime "deleted_at"
  t.datetime "created_at"
  t.datetime "updated_at"
end
ActiveRecord::Base.connection.create_table(:metadata_types) do |t|
  t.string   "name"
  t.text     "description"
  t.string   "tag"
  t.string   "datatype",    :default => "string"
  t.boolean  "mandatory",   :default => false
  t.string   "format"
  t.text     "values"
  t.string   "models",      :default => "--- []"
  t.text     "default"
  t.datetime "deleted_at"
  t.datetime "created_at"
  t.datetime "updated_at"
end
class MyModel < ActiveRecord::Base
  acts_as_metadata
end

describe ActsAsMetadata do
  it 'creates metadata_type' do
    MetadataType.default.save!
    MetadataType.scheme_data.count.should == 1
  end
  
  it 'has default metadata value' do
    mymodel = MyModel.create
    mymodel.sample.should == 'default'
  end

  it 'set metadata value' do
    mymodel = MyModel.new
    mymodel.sample = 'test'
    mymodel.save!
    mymodel = MyModel.last
    mymodel.sample.should == 'test'
  end
  
  it 'updates metadata value' do
    mymodel = MyModel.last
    mymodel.sample = 'test2'
    mymodel.save!
    mymodel = MyModel.last
    mymodel.sample.should == 'test2'
  end
  
  it 'detete metadata when model deleted' do
    MyModel.destroy_all
    Metadata::Metadata.all.count.should == 0
  end
end
