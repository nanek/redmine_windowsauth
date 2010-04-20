require_dependency 'account_controller'

# Patches Redmine's AuthSource dynamically.
module AccountControllerPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
	  
	  alias_method :redmine_login, :login
      alias_method :login, :sso_login
    end
  end
  
  module ClassMethods
    
  end
  
  module InstanceMethods
	
	  # Login request and validation
	  def sso_login
		if request.get?
		  if true #if Setting.ntlm?
			logger.info("WA-PLUGIN: using windows authentication") if logger
			windows_authentication
		  elsif
			logout_user
		  end
		else
		  # Authenticate user
		  if Setting.openid? && using_open_id?
			open_id_authenticate(params[:openid_url])
		  else
			password_authentication
		  end
		end
	  end
  
	  def windows_authentication
		remote_user = request.env['REMOTE_USER']
		logger.info("WA-PLUGIN: remote_user = '#{remote_user}'") if logger
		remote_user_split = remote_user.split('\\')
		domain = remote_user_split[0]
		login = remote_user_split[1]
		logger.info("WA-PLUGIN: Domain='#{domain}' Login='#{login}'") if logger
		user = User.find(:first, :conditions => ["login=?", login])
		if user.nil?
		  #invalid_credentials

		  # Self-registration off
		  redirect_to(home_url) && return unless Setting.self_registration?

		  # user is not yet registered, Create on the fly
		  logger.info("WA-PLUGIN: Calling get_user_from_ldap for '#{login}'") if logger
		  attrs = AuthSource.get_user_from_ldap(login)
		  if attrs
			user = User.new(*attrs)
			user.login = login
			user.language = Setting.default_language
			logger.info("WA-PLUGIN: Saving user '#{user.login}'") if logger
			if user.save
			  user.reload
			  logger.info("WA-PLUGIN: User '#{user.login}' created from LDAP") if logger
			end
		  end
		end
		
		if user.nil?
		  logger.info("WA-PLUGIN: Invalid credentials") if logger
		  invalid_credentials
		else
		  # Valid user
		  logger.info("WA-PLUGIN: Auth success!") if logger
		  successful_authentication(user)
		end
	  end
	
  end    
end

# Add module to AuthSource
AccountController.send(:include, AccountControllerPatch)