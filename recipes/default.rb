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

include_recipe "java"

mflux_home = node['mediaflux']['home']
mflux_user = node['mediaflux']['user']
mflux_user_home = node['mediaflux']['user_home']
mflux_fs = node['mediaflux']['fs']
url = node['mediaflux']['installer_url']

# This is where we look for installers and license key files ...
installers = node['mediaflux']['installers']
if ! installers.start_with?('/') then
  installers = mflux_user_home + '/' + installers
end
installer = node['mediaflux']['installer']

# Can we find a licence file?
have_licence = ::File.exists?("#{mflux_home}/config/licence.xml") ||
   ::File.exists?("#{installers}/licence.xml")

# Can we find an SSL cert file?
have_certs = ::File.exists?("#{mflux_home}/config/certs") ||
   ::File.exists?("#{installers}/certs")

# Do we need an SSL cert file?
need_certs = node['mediaflux']['https_port'] != ''

# This is required to run 'aterm' on a headless machine / virtual
package "xauth" do
  action :install
end

user mflux_user do
  comment "MediaFlux service"
  system true
  shell "/bin/false"
  home mflux_user_home
end

directory mflux_home do
  owner mflux_user
  mode 0755
end

directory mflux_user_home do
  owner mflux_user
  mode 0755
end

directory "#{mflux_user_home}/bin" do
  owner mflux_user
  mode 0755
end

directory "/etc/mediaflux" do
  owner "root"
  mode 0755
end

directory installers do
  owner mflux_user
  mode 0750
end

if url == 'unset' || url == 'change-me' 
  if ! ::File.exists?("#{installers}/#{installer}")
    log 'You must either download the installer by hand' + 
        ' or set the mediaflux.installer_url attribute' do
      level :fatal
    end
    return
  end
else
  remote_file "#{installers}/#{installer}" do
    action :create_if_missing
    source "#{url}/#{installer}"
  end
end

bash "install-mediaflux" do 
  not_if { ::File.exists?("#{mflux_home}/PACKAGE.MF") }
  user mflux_user
  code <<-EOH
java -jar #{installers}/#{installer} nogui << EOF
accept
#{mflux_home}
EOF
EOH
end

link "#{mflux_home}/volatile" do
  to mflux_fs
  only_if { ::File.directory?(mflux_fs) }
end

directory "#{mflux_home}/volatile" do
  owner mflux_user
  not_if { ::File.directory?(mflux_fs) }
end

['logs', 'tmp', 'database', 'stores', 'shopping'].each do |dir|
  directory "#{mflux_home}/volatile/#{dir}" do
    owner mflux_user
  end
end

template "/etc/mediaflux/mfluxrc" do 
  owner "root"
  group mflux_user
  mode 0444
  source "mfluxrc.erb"
  variables({
    :mflux_user => mflux_user,
    :mflux_home => mflux_home,
    :http_port => node['mediaflux']['http_port'],
    :https_port => node['mediaflux']['https_port']
  })
end

template "/etc/mediaflux/servicerc" do 
  action :create_if_missing
  owner "root"
  group mflux_user
  mode 0440
  source "servicerc.erb"
  variables({
    :admin_password => node['mediaflux']['admin_password'],
    :run_as_root => node['mediaflux']['run_as_root']
  })
end

# Just in case someone has editted the file and gotten the access wrong.
bash "fix-permissions" do
  code "chown root:#{mflux_user} /etc/mediaflux/servicerc && " +
       "chmod 0440 /etc/mediaflux/servicerc"
end

template "#{mflux_home}/config/database/database.tcl" do 
  owner mflux_user
  source "database-tcl.erb"
  variables({
    :mflux_home => mflux_home
  })
end

template "#{mflux_home}/config/services/network.tcl" do 
  owner mflux_user
  source "network-tcl.erb"
  variables({
    :http_port => node['mediaflux']['http_port'],
    :https_port => node['mediaflux']['https_port']
  })
end

cookbook_file "#{mflux_user_home}/bin/mfcommand" do 
  owner mflux_user
  mode 0755
  source "mfcommand.sh"
end

cookbook_file "#{mflux_user_home}/bin/mediaflux" do 
  owner mflux_user
  mode 0750
  source "mediaflux-init.sh"
end

cookbook_file "/etc/init.d/mediaflux" do 
  owner "root"
  mode 0750
  source "mediaflux-init.sh"
end

template "#{mflux_user_home}/bin/aterm" do 
  owner mflux_user
  mode 0755
  source "aterm.erb"
  variables({
    :mflux_home => mflux_home
  })
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
  code "cp #{installers}/licence.xml #{mflux_home}/config/licence.xml" +
       " && chmod 444 #{mflux_home}/config/licence.xml"
  creates "#{mflux_home}/config/licence.xml"
  not_if { ::File.exists?("#{mflux_home}/config/licence.xml") }
end

# Install SSL cert if it isn't already installed
if have_certs then
  bash "copy-certs" do
    code "cp #{installers}/certs #{mflux_home}/config/certs" +
         " && chmod 444 #{mflux_home}/config/certs"
    creates "#{mflux_home}/config/certs"
    not_if { ::File.exists?("#{mflux_home}/config/certs") }
  end
end

service "mediaflux" do
  action [ :enable, :restart ]
end

# This is a bit crude, but following recipes may require that the 
# Mediaflux service is 'up'.  
bash "mediaflux-listening" do
  user mflux_user
  code ". /etc/mediaflux/mfluxrc ; " +
       "wget ${MFLUX_TRANSPORT}://${MFLUX_HOST}:${MFLUX_PORT}/ " +
       "    --retry-connrefused --no-check-certificate -O /dev/null " +
       "    --waitretry=1 --timeout=2 --tries=10"
end 
