require_dependency 'auth_source'

# Patches Redmine's AuthSource dynamically.
module AuthSourcePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
    end

  end
  
  module ClassMethods
  
    def get_user_from_ldap(login)
	  AuthSource.find(:all, :conditions => ["onthefly_register=?", true]).each do |source|
	  begin
		  logger.info "WA-PLUGIN: Authenticating '#{login}' against '#{source.name}'" if logger
		  attrs = source.get_user_from_ldap(login)
		rescue => e
		  logger.error "WA-PLUGIN: Error during authentication: '#{e.message}'"
		  attrs = nil
		end
		return attrs if attrs
	  end
	  return nil
    end
	
  end
  
  module InstanceMethods
	
	def get_user_from_ldap(login)
	end
	
  end    
end

# Add module to AuthSource
AuthSource.send(:include, AuthSourcePatch)