module Metadata
  class Metadata < ActiveRecord::Base
    serialize :value
    default_scope :conditions => {:deleted_at => nil}, :order => 'created_at DESC'
    
    def undelete
      self.deleted_at=nil
      self.save
		end
      
    def destroy(real = false)
      if real
        Metadata.unscoped.delete_all(:id => self.id)
      else
        self.run_callbacks(:destroy)
        self.update_attribute(:deleted_at, Time.now.utc)
      end
    end
  end
end
