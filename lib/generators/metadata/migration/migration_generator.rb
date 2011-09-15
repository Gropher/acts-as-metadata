require 'rails/generators'
require 'rails/generators/migration'

module Metadata
  class MigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    
    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end
    
    
    def self.next_migration_number(dirname)
      #if ActiveRecord::Base.timestamped_migrations
        Time.now.utc.strftime("%Y%m%d%H%M%S")
        "%.3d" % (current_migration_number(dirname) + 1)
      #end
    end

    def create_migration_file
      migration_template 'migration.rb', 'db/migrate/create_metadata.rb'
    end
  end
end
