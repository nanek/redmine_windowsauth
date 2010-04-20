require 'redmine'

# Patches to the Redmine core.
require_dependency 'auth_source_patch'
require_dependency 'auth_source_ldap_patch'
require_dependency 'account_controller_patch'

Redmine::Plugin.register :redmine_ntlm do
  name 'Redmine Windows Authentication plugin'
  author 'Kenan Shifflett'
  description 'This is a plugin for Redmine that allows SSO with Windows Authentication'
  version '0.0.1'
end
