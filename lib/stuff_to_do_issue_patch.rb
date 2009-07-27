# Patches Redmine's Issues dynamically.  Adds a +after_save+ filter.
module StuffToDoIssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      after_save :update_next_issues
      has_many :stuff_to_dos, :as => :stuff

      named_scope :with_time_entries_for_user, lambda {|user_id|
        {
          :include => :time_entries,
          :conditions => ["#{TimeEntry.table_name}.user_id = (?)", user_id]
        }
      }
      
      named_scope :with_time_entries_within_date, lambda {|date_from, date_to,|
        {
          :include => :time_entries,
          :conditions => ["#{TimeEntry.table_name}.spent_on > (:from) AND #{TimeEntry.table_name}.spent_on < (:to)",
                          {:from => date_from, :to => date_to}]
        }
      }
      
    end

  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    # This will update all NextIssues assigned to the Issue
    #
    # * When an issue is closed, NextIssue#remove_associations_to will be called to
    #   update the set of NextIssues
    # * When an issue is reassigned, any previous (stale) NextIssues will
    #   be removed
    def update_next_issues
      self.reload
      StuffToDo.remove_associations_to(self) if self.closed?
      StuffToDo.remove_stale_assignments(self)
      return true
    end
  end    
end
