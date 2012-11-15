require 'spec_helper'

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

  it 'checks presence validation' do
    mt = MetadataType.first
    mt.mandatory = true
    mt.default = nil
    mt.save!
    mymodel = MyModel.new
    mymodel.save
    mymodel.errors.include?(:sample).should == true
    mymodel.sample = 'wqwewew'
    mymodel.save
    mymodel.errors.count.should == 0
  end

  it 'checks format validation' do
    mt = MetadataType.first
    mt.mandatory = false
    mt.format = '[a-z]*'
    mt.save!
    mymodel = MyModel.new
    mymodel.sample = '12323'
    mymodel.save
    mymodel.errors.include?(:sample).should == true
    mymodel.sample = 'wqwewew'
    mymodel.save
    mymodel.errors.count.should == 0
  end

  it 'checks values validation' do
    mt = MetadataType.first
    mt.values = ['aaa', 'bbb']
    mt.save!
    mymodel = MyModel.new
    mymodel.sample = 'ccc'
    mymodel.save
    mymodel.errors.include?(:sample).should == true
    mymodel.sample = 'bbb'
    mymodel.save
    mymodel.errors.count.should == 0
  end

  it 'creates multiple metadata items for array metadata' do
    MetadataType.destroy_all
    mt = MetadataType.default
    mt.tag = :samplearray
    mt.name = "Sample Array"
    mt.datatype = :array
    mt.save!
    mymodel = MyModel.new
    mymodel.samplearray = ['aaa', 'bbb', 'ccc']
    mymodel.save
    mymodel.errors.count.should == 0
    mymodel.metadata.count.should == 3
  end

  it 'loads array metadata correctly' do
    mymodel = MyModel.new
    mymodel.samplearray = ['aaa', 'bbb', 'ccc']
    mymodel.save
    mymodel.errors.count.should == 0
    mymodel.metadata_cache = nil
    mymodel.samplearray.count.should == 3
  end

  it 'checks presence validation for array metadata' do
    mt = MetadataType.first
    mt.mandatory = true
    mt.default = nil
    mt.save!
    mymodel = MyModel.new
    mymodel.save
    mymodel.errors.include?(:samplearray).should == true
    mymodel.samplearray = ['abc']
    mymodel.save
    mymodel.errors.count.should == 0
  end

  it 'checks format validation for array metadata' do
    mt = MetadataType.first
    mt.mandatory = false
    mt.format = '[a-z]*'
    mt.save!
    mymodel = MyModel.new
    mymodel.samplearray = ['123', '456', 'ccc']
    mymodel.save
    mymodel.errors.count.should == 2
    mymodel.samplearray = ['aaa', 'bbb', 'ccc']
    mymodel.save
    mymodel.errors.count.should == 0
  end
  
  it 'checks values validation for array metadata' do
    mt = MetadataType.first
    mt.mandatory = false
    mt.values = ['aaa', 'bbb', 'ccc']
    mt.save!
    mymodel = MyModel.new
    mymodel.samplearray = ['ddd', 'eee', 'ccc']
    mymodel.save
    mymodel.errors.count.should == 2
    mymodel.samplearray = ['aaa', 'bbb', 'ccc']
    mymodel.save
    mymodel.errors.count.should == 0
  end  
end
