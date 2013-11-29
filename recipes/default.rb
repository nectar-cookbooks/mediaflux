#
# Cookbook Name:: mediaflux
# Recipe:: default
#
# Copyright (c) 2013, The University of Queensland
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# * Neither the name of the The University of Queensland nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE UNIVERSITY OF QUEENSLAND BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

include_recipe "mediaflux::common"

mflux_home = node['mediaflux']['home']
mflux_bin = node['mediaflux']['bin'] || "#{mflux_home}/bin"
mflux_config = "#{mflux_home}/config"
mflux_user = node['mediaflux']['user']
mflux_user_home = node['mediaflux']['user_home'] || mflux_home
mflux_fs = node['mediaflux']['volatile']
url = node['mediaflux']['installer_url']

domain = node['mediaflux']['authentication_domain'] || 'users'

mfcommand = "#{mflux_bin}/mfcommand"

# This is where we look for installers and license key files ...
installers = node['mediaflux']['installers'] || 'installers'
if ! installers.start_with?('/') then
  installers = mflux_user_home + '/' + installers
end
installer = node['mediaflux']['installer']

# Can we find a licence file?
have_licence = ::File.exists?("#{mflux_config}/licence.xml") ||
   ::File.exists?("#{installers}/licence.xml")

# Can we find an SSL cert file?
have_certs = ::File.exists?("#{mflux_config}/certs") ||
   ::File.exists?("#{installers}/certs")

# Do we need an SSL cert file?
need_certs = node['mediaflux']['https_port'] != ''

# Recover the admin password (if any) from the current installation to
# avoid clobbering it.
if File::exists?('/etc/mediaflux/servicerc') then
  admin_password = `. /etc/mediaflux/servicerc && echo $MFLUX_PASSWORD`.strip()
else
  admin_password = 'change_me'
end

# This is required to run 'aterm' on a headless machine / virtual
package "xauth" do
  action :install
end

# Create the service user
user mflux_user do
  comment "MediaFlux service"
  system true
  shell "/bin/false"
  home mflux_user_home
end

if mflux_user_home != mflux_home then
  directory mflux_user_home do
    owner mflux_user
    mode 0755
  end
end

directory installers do
  owner mflux_user
  mode 0750
end

if url == nil
  if ! ::File.exists?("#{installers}/#{installer}")
    raise 'You must either download the Mediaflux installer by hand' + 
        ' or set the mediaflux.installer_url attribute'
  end
else
  remote_file "#{installers}/#{installer}" do
    action :create_if_missing
    source "#{url}/#{installer}"
  end
end

if ! File.exists?("#{mflux_home}/PACKAGE.MF") &&
    node['mediaflux']['accept_license_agreement'] != true then
  raise 'You must either run the Mediaflux installer by hand' + 
    ' or set the mediaflux.accept_license_agreement attribute to true' +
    ' to signify that you have read and accept the Mediaflux license'
end

bash "install-mediaflux" do 
  not_if { File.exists?("#{mflux_home}/PACKAGE.MF") }
  code <<-EOH
java -jar #{installers}/#{installer} nogui << EOF
accept
#{mflux_home}
EOF
EOH
  notifies :run, "bash[tweak-installation]", :immediately
end

# Two files need to be replaced if and only if the installer just 
# deposited them.  Also, we need to change the file ownership of the
# installed files ...
bash "tweak-installation" do
  action :nothing
  code "rm #{mflux_config}/services/network.tcl && " +
    "rm #{mflux_config}/database/database.tcl && " +
    "chown -R #{mflux_user}:#{mflux_user} #{mflux_home}"
end

link "#{mflux_home}/volatile" do
  to mflux_fs
  only_if { mflux_fs && ::File.directory?(mflux_fs) }
end

directory "#{mflux_home}/volatile" do
  owner mflux_user
  not_if { mflux_fs && ::File.directory?(mflux_fs) }
end

bash "set-volatile-owner" do
  code "chown --dereference #{mflux_user}:#{mflux_user} #{mflux_home}/volatile"
end

['logs', 'tmp', 'database', 'stores', 'shopping'].each do |dir|
  directory "#{mflux_home}/volatile/#{dir}" do
    owner mflux_user
  end
end

template "/etc/mediaflux/servicerc" do 
  owner "root"
  group mflux_user
  mode 0440
  source "servicerc.erb"
  variables({
    :mflux_user => mflux_user,
    :admin_password => admin_password,
    :run_as_root => node['mediaflux']['run_as_root']
  })
end

# Just in case someone has editted the file and gotten the access wrong.
bash "fix-permissions" do
  code "chown root:#{mflux_user} /etc/mediaflux/servicerc && " +
       "chmod 0440 /etc/mediaflux/servicerc"
end

template "#{mflux_bin}/change-mf-password.sh" do
  source "change-mf-password.erb"
  owner 'root'
  group mflux_user
  mode 0755
  variables ({
               :mflux_user_home => mflux_user_home
             })
end

template "#{mflux_config}/database/database.tcl" do 
  owner mflux_user
  source "database-tcl.erb"
  variables({
    :mflux_home => mflux_home
  })
  # This could have been tailored by a layered application ...
  not_if { ::File.exists?("#{mflux_config}/database/database.tcl") }
end

template "#{mflux_config}/services/network.tcl" do 
  owner mflux_user
  source "network-tcl.erb"
  variables({
    :http_port => node['mediaflux']['http_port'],
    :https_port => node['mediaflux']['https_port']
  })
  # This could have been tailored by a layered application ...
  not_if { ::File.exists?("#{mflux_config}/services/network.tcl") }
end

cookbook_file "#{mflux_bin}/mediaflux" do 
  owner mflux_user
  mode 0750
  source "mediaflux-init.sh"
end

cookbook_file "/etc/init.d/mediaflux" do 
  owner "root"
  mode 0750
  source "mediaflux-init.sh"
end

if ! have_licence then
  # This is as far as we can go without a licence file ... 
  log "Please place a copy of your MediaFlux licence file in " +
      "#{mflux_user_home}/installers/licence.xml and then rerun this recipe" do
    level :fatal
  end
  ruby_block "bail-out" do
    block do 
      raise "Bailing out - see previous 'fatal' log message"
    end
  end
end

if ! have_certs && need_certs then
  log "Please create or obtain an SSL certificate, and copy it to " +
      "#{mflux_user_home}/installers/certs and then rerun this recipe. " +
      "(A self-signed certificate will do ... for now.)" do
    level :fatal
  end
  ruby_block "bail-out" do
    block do 
      raise "Bailing out - see previous 'fatal' log message"
    end
  end
end

# Install licence file if it isn't already installed
bash "copy-licence" do
  code "cp #{installers}/licence.xml #{mflux_config}/licence.xml" +
       " && chmod 444 #{mflux_config}/licence.xml"
  creates "#{mflux_config}/licence.xml"
  not_if { ::File.exists?("#{mflux_config}/licence.xml") }
end

# Install SSL cert if it isn't already installed
if have_certs then
  bash "copy-certs" do
    code "cp #{installers}/certs #{mflux_config}/certs" +
         " && chmod 444 #{mflux_config}/certs"
    creates "#{mflux_config}/certs"
    not_if { ::File.exists?("#{mflux_config}/certs") }
  end
end

template "#{mflux_config}/initial_mflux_conf.tcl" do 
  source "initial_mflux_conf.erb"
  owner mflux_user
  group mflux_user
  mode 0400
  helpers (MfluxHelpers)
  variables ({
               :server_name => node['mediaflux']['server_name'],
               :server_organization => node['mediaflux']['server_organization'],
               :jvm_memory_max => node['mediaflux']['jvm_memory_max'],
               :jvm_memory_perm_max => node['mediaflux']['jvm_memory_max'],
               :mail_smtp_host => node['mediaflux']['mail_smtp_host'],
               :mail_smtp_port => node['mediaflux']['mail_smtp_port'],
               :mail_from => node['mediaflux']['mail_from'],
               :notification_from => node['mediaflux']['notification_from'],
               :authentication_domain => domain
             })
end

include_recipe "mediaflux::aar"

include_recipe "mediaflux::aterm"


# The 'defer_start' hack allows another recipe to do stuff
# before the mediaflux service is started.
if node['mediaflux']['defer_start'] then
  service 'mediaflux' do
    action :enable
  end
else
  service 'mediaflux' do
    action [:enable, :restart]
    notifies :run, "bash[mediaflux-running]", :immediately    
  end

  # Some initial configuration of the mediaflux service
  bash 'run-server-config' do
    code ". /etc/mediaflux/servicerc && " +
      "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
      "#{mfcommand} source #{mflux_config}/initial_mflux_conf.tcl && " +
      "#{mfcommand} logoff"
    notifies :restart, "service[mediaflux-restart]", :immediately    
  end

  service 'mediaflux-restart' do
    service_name 'mediaflux'
    action :nothing
    notifies :run, "bash[mediaflux-running]", :immediately    
  end

  bash "mediaflux-running" do
    action :nothing
    user mflux_user
    code ". /etc/mediaflux/mfluxrc ; " +
      "wget ${MFLUX_TRANSPORT}://${MFLUX_HOST}:${MFLUX_PORT}/ " +
      "    --retry-connrefused --no-check-certificate -O /dev/null " +
      "    --waitretry=1 --timeout=2 --tries=30"
  end
end

backup_dir = node['mediaflux']['backup_dir'] || "#{mflux_home}/volatile/backups"
backup_replica = node['mediaflux']['backup_replica']
backup_keep_days = node['mediaflux']['backup_keep_days'] || 5

template "#{mflux_home}/bin/backup.sh" do
  source 'backup_sh.erb'
  owner mflux_user
  mode 0700
  variables ({
               'backup_dir' => backup_dir,
               'replica' => backup_replica,
               'keep_days' => backup_keep_days
             })
end

cookbook_file "#{mflux_config}/backup.tcl" do
  source 'backup.tcl'
  owner mflux_user
  mode 0600
end

if node['mediaflux']['backup_cron'] then
  times = node.default['mediaflux']['backup_cron_times']
  mailto = node.default['mediaflux']['backup_cron_mailto'] || ''
  cron 'mediaflux_backup_cron' do
    command "#{mflux_home}/bin/backup.sh"
    minute times[0]
    hour times[1]
    day times[2]
    month times[3]
    weekday times[4]
    mailto mailto
    user mflux_user
  end
end
