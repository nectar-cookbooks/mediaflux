#
# Cookbook Name:: mediaflux
# Recipe:: default
#
# Copyright (c) 2013, 2014, The University of Queensland
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
include_recipe "mediaflux::logwatch"
include_recipe 'mediaflux::installer_cache'

mflux_home = node['mediaflux']['home']
mflux_bin = node['mediaflux']['bin'] || "#{mflux_home}/bin"
mflux_config = "#{mflux_home}/config"
mflux_user = node['mediaflux']['user']
mflux_user_home = node['mediaflux']['user_home'] || mflux_home
mflux_fs = node['mediaflux']['volatile']
reinstall = node['mediaflux']['reinstall']

domain = node['mediaflux']['authentication_domain'] || 'users'

mfcommand = "#{mflux_bin}/mfcommand"

# This is where we look for installers and license key files ...
installers = node['mediaflux']['installers'] || 'installers'
if ! installers.start_with?('/') then
  installers = mflux_user_home + '/' + installers
end

url = node['mediaflux']['installer_url']
installer = node['mediaflux']['installer']
base_url = node['mediaflux']['download_base_url']
version = node['mediaflux']['version']

if url then
  m = /.+\/([^\/]+\.jar)$/.matches(url)
  unless m then
    raise "Installer URL (#{url}) isn't for a JAR file"
  end
  if installer && m[1] != installer then
    raise "Installer JAR file (#{installer}) doesn't match URL (#{url})"
  else
    installer = m[1]
  end
end

if installer then
  m = /.+_(\d\.\d\.\d\d\d)_jvm_(\d\.\d)\.jar$/.matches(installer)
  unless m then
    raise "Cannot parse the installer name"
  end
  if !version then
    version = m[1]
  elsif version != m[1] then
    raise "We need Mediaflux #{version} but the supplied 'installer' " +
      "or 'installer_url' is for #{m[1]}"
  end
elsif version then 
  installer = "mflux-dev_#{version}_jvm_1.6.jar"
else
  raise "Nothing specifies a Mediaflux version.  You need to specify it " +
    "directly via the 'version' attribute, or indirectly in the 'installer' " +
    "or 'unstaller_url'"
end

if base_url && !url then
  url = "#{base_url}/#{version}/#{installer}"
end
  
if !url && !::File.exists?("#{installers}/#{installer}")
    raise "Mediaflux installer #{installer} needs to be downloaded by hand" +
      "and placed in #{installers}"
end

raise "Bailing out: '#{url}', '#{installer}', '#{version}'"

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
  shell "/bin/bash"
  home mflux_user_home
end

directory "mflux user home directory" do
  path mflux_user_home
  owner mflux_user
  group mflux_user
  mode 0755
end

if url then
  remote_file "#{installers}/#{installer}" do
    action :create_if_missing
    source url
  end
end

if ! File.exists?("#{mflux_home}/PACKAGE.MF") then
  if node['mediaflux']['accept_license_agreement'] != true then
    raise 'You must either run the Mediaflux installer by hand' + 
      ' or set the mediaflux.accept_license_agreement attribute to true' +
      ' to signify that you have read and accept the Mediaflux license'
  end
end

if reinstall then
  service 'mediaflux-stop-to-reinstall' do
    service_name 'mediaflux'
    action :stop
  end
  bash "install-mediaflux" do 
    code <<-EOH
java -jar #{installers}/#{installer} nogui << EOF
accept
#{mflux_home}
y
EOF
EOH
    notifies :run, "bash[tweak-installation]", :immediately
  end
else 
  bash "install-mediaflux" do 
    only_if { ! File.exists?("#{mflux_home}/PACKAGE.MF") }
    code <<-EOH
java -jar #{installers}/#{installer} nogui << EOF
accept
#{mflux_home}
EOF
EOH
    notifies :run, "bash[tweak-installation]", :immediately
  end
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

#
# Since the license and keystore may be delivered by another recipe,
# these checks must be done during convergence ...
#
ruby_block "check licence and certs" do
  block do
    # Can we find a licence file (installed or in the installer area)?
    if ! (::File.exists?("#{mflux_config}/licence.xml") ||
          ::File.exists?("#{installers}/licence.xml")) then
      raise "Please place a copy of your MediaFlux licence file in " +
        "#{mflux_user_home}/installers/licence.xml.  Then rerun this recipe"
    end
    if need_certs then
      # Can we find a keystore (installed or not ...)?
      if ! (::File.exists?("#{mflux_config}/certs") ||
            ::File.exists?("#{installers}/certs")) then
        raise "Please create a suitable keystore and put here - " +
          "#{mflux_user_home}/installers/certs.  Then rerun this recipe."
      end
    end
  end
end

# Install licence file if it isn't already installed
bash "copy licence" do
  code "cp #{installers}/licence.xml #{mflux_config}/licence.xml" +
       " && chmod 444 #{mflux_config}/licence.xml"
  creates "#{mflux_config}/licence.xml"
  not_if { ::File.exists?("#{mflux_config}/licence.xml") }
end

# Install "certs" keystore if it isn't already installed
bash "copy certs" do
  code "cp #{installers}/certs #{mflux_config}/certs" +
    " && chmod 444 #{mflux_config}/certs"
  creates "#{mflux_config}/certs"
  only_if {
    ::File.exists?("#{installers}/certs") && 
    ! ::File.exists?("#{mflux_config}/certs") }
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


service 'mediaflux' do
  action :enable
end

service 'mediaflux-restart-A' do
  service_name 'mediaflux'
  action :restart
  notifies :run, "bash[mediaflux-running-A]", :immediately    
end

bash "mediaflux-running-A" do
  action :nothing
  user mflux_user
  code ". /etc/mediaflux/mfluxrc ; " +
    "wget ${MFLUX_TRANSPORT}://${MFLUX_HOST}:${MFLUX_PORT}/ " +
    "    --retry-connrefused --no-check-certificate -O /dev/null " +
    "    --secure-protocol=SSLv3 --waitretry=1 --timeout=2 --tries=30"
  notifies :run, "bash[run-server-config]", :immediately    
end

# Some initial configuration of the mediaflux service
bash 'run-server-config' do
  action :nothing
  code ". /etc/mediaflux/servicerc && " +
    "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
    "#{mfcommand} source #{mflux_config}/initial_mflux_conf.tcl && " +
    "#{mfcommand} logoff"
  notifies :restart, "service[mediaflux-restart-B]", :immediately    
end

service 'mediaflux-restart-B' do
  service_name 'mediaflux'
  action :nothing
  notifies :run, "bash[mediaflux-running-B]", :immediately    
end

bash "mediaflux-running-B" do
  action :nothing
  user mflux_user
  code ". /etc/mediaflux/mfluxrc ; " +
    "wget ${MFLUX_TRANSPORT}://${MFLUX_HOST}:${MFLUX_PORT}/ " +
    "    --retry-connrefused --no-check-certificate -O /dev/null " +
    "    --secure-protocol=SSLv3 --waitretry=1 --timeout=2 --tries=30"
end

include_recipe 'mediaflux::backups'
