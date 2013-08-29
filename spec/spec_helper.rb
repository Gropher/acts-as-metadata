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
Rails.cache = ActionController::Base.cache_store

RSpec.configure do |config|
  # some (optional) config here
end

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'my_models'")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'metadata'")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'metadata_types'")
ActiveRecord::Base.connection.create_table(:my_models) do |t|
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
  t.string   "search_value"
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
  t.boolean  "multiple",   :default => false
  t.string   "format"
  t.text     "values"
  t.string   "models",      :default => "--- []"
  t.text     "default"
  t.datetime "deleted_at"
  t.datetime "created_at"
  t.datetime "updated_at"
end
