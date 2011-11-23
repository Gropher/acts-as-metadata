require 'rubygems'
require 'bundler/setup'

require 'rails/all'
require 'acts_as_metadata' # and any other gems you need

root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
ActiveRecord::Base.establish_connection(
	:adapter => "sqlite3",
	:database => "#{root}/db/acts_as_metadata.db"
)
ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
RAILS_CACHE = ActionController::Base.cache_store

RSpec.configure do |config|
  # some (optional) config here
end
