module Metadata
  class Metadata < ActiveRecord::Base
    before_save :set_search_value
  protected
    def set_search_value
      self.search_value = value.to_s[0,255] rescue nil
    end
  end
end
