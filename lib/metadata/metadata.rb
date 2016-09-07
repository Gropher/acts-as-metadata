module Metadata
  class Metadata < ActiveRecord::Base
    # default_scope :conditions => {:deleted_at => nil}, :order => 'created_at DESC'
    before_save :set_search_value

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

  protected
    def set_search_value
      self.search_value = value.to_s[0,255] rescue nil
    end
  end
end
