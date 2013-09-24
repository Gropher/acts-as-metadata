# ActsAsMetadata

Dynamicly add unlimited number of indexed, searchable, validatable, strongly typed fields to your ActiveRecord models.

## Installation

Add this line to your application's Gemfile:

    gem 'acts_as_metadata'

And then execute:

    $ bundle

Or install it manually:

    $ gem install acts_as_metadata

## Usage

Generate migration that creates metadata tables: 

    $ rails g metadata:migration

Add acts_as_metadata to your model:

    class MyModel < ActiveRecord::Base
      acts_as_metadata
    end

and create metadata_cache column to speed up metadata extraction:

    rails g migration AddMetadataCacheToMyModels metadata_cache:text

Create metadata types in your database:

    mt = MetadataType.create! :tag => :sample, :name => "Sample", :datatype => :string

Its ready to use:

    m = MyModel.new
    m.m_sample = 'some string'
    m.save!

Add some validations or default value if you need:

    mt.default   = 'some default string' 
    mt.mandatory = true                   # presence validation
    mt.format    = "[a-z]*"               # regexp validation
    mt.values    = ['aaa', 'bbb', 'ccc']  # inclusion validation
    mt.save!

There are more usage examples in spec directory.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
