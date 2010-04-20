require_dependency 'auth_source_ldap'

# Patches Redmine's AuthSource dynamically.
module AuthSourceLdapPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
    end

  end
  
  module ClassMethods
  
  end
  
  module InstanceMethods
	
	  def get_user_from_ldap(login)
		return nil if login.blank?
		attrs = []
		# get user's DN
		logger.info("WA-PLUGIN: Initializing LDAP connection") if logger
		ldap_con = initialize_ldap_con(self.account, self.account_password)
		login_filter = Net::LDAP::Filter.eq( self.attr_login, login ) 
		object_filter = Net::LDAP::Filter.eq( "objectClass", "*" ) 
		dn = String.new
		logger.info("WA-PLUGIN: Searching LDAP for user") if logger
		ldap_con.search( :base => self.base_dn, 
						 :filter => object_filter & login_filter, 
						 # only ask for the DN if on-the-fly registration is disabled
						 :attributes=> (onthefly_register? ? ['dn', self.attr_firstname, self.attr_lastname, self.attr_mail] : ['dn'])) do |entry|
		  dn = entry.dn
		  logger.info("WA-PLUGIN: Setting attributes array") if logger
		  attrs = [:firstname => AuthSourceLdap.get_attr(entry, self.attr_firstname),
				   :lastname => AuthSourceLdap.get_attr(entry, self.attr_lastname),
				   :mail => AuthSourceLdap.get_attr(entry, self.attr_mail),
				   :auth_source_id => self.id ] if onthefly_register?
		  logger.info("WA-PLUGIN: Attributes set successfully") if logger
		end
		return nil if dn.empty?
		logger.info("WA-PLUGIN: DN found for #{login}: #{dn}") if logger
		attrs    
	  rescue  Net::LDAP::LdapError => text
	      logger.error("WA-PLUGIN: Error in get_user_from_ldap: '#{text.message}'")
		raise "LdapError: " + text
	  end
	  
  end    
end

# Add module to AuthSource
AuthSourceLdap.send(:include, AuthSourceLdapPatch)