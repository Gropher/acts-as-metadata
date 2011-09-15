require "active_record"
require "action_view"

require 'metadata/metadata'
require 'metadata/metadata_type'
require 'metadata/acts_as_metadata'
require 'metadata/acts_as_metadata_helper'
require 'metadata/version'

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend ActsAsMetadata
end

module ApplicationHelper
  include ActsAsMetadataHelper
end

module ActsAsMetadata
  # Your code goes here...
end
