node.default['mediaflux']['home'] = '/opt/mflux'   # mediaflux install directory
node.default['mediaflux']['bin'] = nil
node.default['mediaflux']['user'] = 'mflux'        # system user ... and home
node.default['mediaflux']['user_home'] = nil
node.default['mediaflux']['volatile'] = nil        # separate data directory

node.default['mediaflux']['installers'] = 'installers'

# The following attributes control what version of Mediaflux to use, what
# installer to use, and where to get it from (if it needs to be downloaded).
node.default['mediaflux']['installer_url'] = nil
node.default['mediaflux']['download_base_url'] = nil
node.default['mediaflux']['version'] = nil
node.default['mediaflux']['installer'] = nil

node.default['mediaflux']['host'] = nil           # defaults to "this host"

# This should be set to true to signify that you have read, and accepted 
# the Mediaflux license agreement.
node.default['mediaflux']['accept_license_agreement'] = nil

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
node.default['mediaflux']['authentication_domain'] = nil

node.default['mediaflux']['install_java'] = true
node.default['mediaflux']['java_command'] = nil

# These java opts go into the common 'mfluxrc' file and are available 
# for mediaflux and 3rd-party Java clients ... as $MFLUX_JAVA_OPTS
node.default['mediaflux']['client_jvm_opts'] = ''

# These apply to the mediaflux server only.
node.default['mediaflux']['jvm_memory_max'] = nil
node.default['mediaflux']['jvm_memory_perm_max'] = '512'
node.default['mediaflux']['jvm_opts'] = ''

node.normal['java']['install_flavor'] = 'openjdk'
node.normal['java']['jdk_version'] = '7'
node.normal['java']['accept_license_agreement'] = true
node.normal['java']['oracle']['accept_oracle_download_terms'] = true

# Mediaflux backup configuration
node.default['mediaflux']['backup_dir'] = nil
node.default['mediaflux']['backup_replica'] = nil
node.default['mediaflux']['backup_store'] = nil
node.default['mediaflux']['backup_keep_days'] = nil
node.default['mediaflux']['backup_keep_sets'] = nil
node.default['mediaflux']['backup_cron'] = false
node.default['mediaflux']['backup_cron_mailto'] = nil
node.default['mediaflux']['backup_cron_times'] = [ "0", "2", "*", "*", "*" ]
node.default['mediaflux']['backup_cron_mailto'] = nil

node.default['mediaflux']['external_asset_backup'] = true
node.default['mediaflux']['backup_wrapper'] = 'tar_gz_wrapper'

# This is just the initial list.  A downstream recipe may add additional
# stores by looking up the relevant resource and appending to the relevant
# template variable.
node.default['mediaflux']['stores'] = []

# This says to reinstall (e.g. upgrade) the Mediaflux installation.
node.default['mediaflux']['reinstall'] = false

# This workaround comes from CHEF-4234.  It forces the "java" recipe attributes
# to be reloaded, and the ones that interpolate the above to be re-evaluated.
node.from_file(run_context.resolve_attribute(*parse_attribute_file_spec("java")))
