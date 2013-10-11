node.default['mediaflux']['home'] = '/opt/mflux'   # install directory
node.default['mediaflux']['user'] = 'mflux'        # system user ... and home
node.default['mediaflux']['user_home'] = '/usr/local/mediaflux'
node.default['mediaflux']['fs'] = '/data'          # separate data directory

# This should be overridden in the node or role definitions.  If it is
# left "unset" then the recipe assumes that the installer has already been
# downloaded and placed in the installation directory as "installer.jar"
node.default['mediaflux']['installer_url'] = 'unset'

# This is the default password as per the mediaflux installation guide ...
node.default['mediaflux']['admin_password'] = 'Y2hhbmdlX21lCg=='

# If either of these is unset then the corresponding service endpoint
# is not enabled.  Note that we default to using "high" ports because of
# the difficulty of getting a non-root Java application to bind to a 
# privileged port.
node.default['mediaflux']['http_port'] = '8080'
node.default['mediaflux']['https_port'] = '8443'

node.normal['java']['install_flavor'] = 'openjdk'
node.normal['java']['jdk_version'] = '7'
node.normal['java']['accept_license_agreement'] = true

# This workaround comes from CHEF-4234.  It forces the "java" recipe attributes
# to be reloaded, and the ones that interpolate the above to be re-evaluated.
node.from_file(run_context.resolve_attribute(*parse_attribute_file_spec("java")))
