module Metadata
  class Metadata < ActiveRecord::Base
    serialize :value
    default_scope :conditions => {:deleted_at => nil}, :order => 'created_at DESC'
      
    def destroy
      self.run_callbacks(:destroy)
      self.update_attribute(:deleted_at, Time.now.utc)
    end
  end
end
