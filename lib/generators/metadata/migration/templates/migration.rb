class CreateMetadata < ActiveRecord::Migration
  def self.up
    create_table :metadata do |t|
      t.column :id, :integer
      t.column :metadata_type, :string
      t.column :model_id, :integer
      t.column :model_type, :string
      t.column :value, :text
      t.column :search_value, :string
      
      t.timestamp :deleted_at, :default => nil
      t.timestamps
    end
    
    create_table :metadata_types do |t|
      t.column :id, :integer
      t.column :name, :string
      t.column :description, :text
      t.column :tag, :string
			t.column :datatype, :string, :default => "string"
      t.column :mandatory, :boolean, :default => false
      t.column :multiple, :boolean, :default => false
      t.column :format, :string
      t.column :values, :text
      t.column :models, :string, :default => '--- []'
      t.column :default_value, :text     
 
      t.timestamp :deleted_at, :default => nil
      t.timestamps
    end
    
    add_index :metadata_types, :datatype
    add_index :metadata_types, :tag, :unique => true
    add_index :metadata, :metadata_type
    add_index :metadata, [:metadata_type, :search_value]
    add_index :metadata, [:model_id, :model_type]
  end
  
  def self.down
    drop_table :metadata
    drop_table :metadata_types
  end
end
