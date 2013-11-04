node.default['mediaflux']['home'] = '/opt/mflux'   # install directory
node.default['mediaflux']['user'] = 'mflux'        # system user ... and home
node.default['mediaflux']['user_home'] = '/usr/local/mediaflux'
node.default['mediaflux']['fs'] = nil              # separate data directory

node.default['mediaflux']['installers'] = 'installers'

node.default['mediaflux']['installer'] = 'mflux-dev_3.8.038_jvm_1.6.jar' 

# This should be overridden in the node or role definitions.  If it is
# left "unset" then the recipe assumes that the installer has already been
# downloaded and placed in the installation directory as "installer.jar"
node.default['mediaflux']['installer_url'] = 'unset'

# If either of these is unset then the corresponding service endpoint
# is not enabled.  Note that we default to using "high" ports because of
# the difficulty of getting a non-root Java application to bind to a 
# privileged port.  Setting either port to an empty string will disable
# the corresponding transport
node.default['mediaflux']['http_port'] = '8080'
node.default['mediaflux']['https_port'] = '8443'
node.default['mediaflux']['run_as_root'] = false

node.default['mediaflux']['server_name'] = node['hostname']
node.default['mediaflux']['server_organization'] = 'Unspecified Organization'
node.default['mediaflux']['mail_smtp_host'] = ''
node.default['mediaflux']['mail_smtp_port'] = '25'
node.default['mediaflux']['mail_from'] = ''
node.default['mediaflux']['notification_from'] = ''
node.default['mediaflux']['authentication_domain'] = ''

node.default['mediaflux']['install_java'] = true
node.default['mediaflux']['java_command'] = nil

# These apply to the mediaflux server only.
node.default['mediaflux']['jvm_memory_max'] = nil
node.default['mediaflux']['jvm_memory_perm_max'] = '512'
node.default['mediaflux']['jvm_opts'] = ''

node.normal['java']['install_flavor'] = 'openjdk'
node.normal['java']['jdk_version'] = '7'
node.normal['java']['accept_license_agreement'] = true

# This workaround comes from CHEF-4234.  It forces the "java" recipe attributes
# to be reloaded, and the ones that interpolate the above to be re-evaluated.
node.from_file(run_context.resolve_attribute(*parse_attribute_file_spec("java")))

# This is "internal" to the recipe and others that depend on it.
node.default['mediaflux']['defer_start'] = false
