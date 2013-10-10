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

# Can we find a license file?
have_license = ::File.exists?("#{mflux_home}/config/license.xml") ||
   ::File.exists?("#{mflux_user_home}/license.xml")

user mflux_user do
  comment "MediaFlux service"
  system true
  shell "/bin/false"
  home mflux_user_home
end

directory mflux_home do
  owner mflux_user
end

directory mflux_user_home do
  owner mflux_user
end

directory "#{mflux_user_home}/bin" do
  owner mflux_user
end

if url == 'unset' || url == 'change-me' 
  if ! ::File.exists?("#{mflux_home}/installer.jar")
    log 'You must either download the installer by hand' + 
        ' or set the mediaflux.installer_url attribute' do
      level :fatal
    end
    return
  end
else
  remote_file "#{mflux_home}/installer.jar" do
    action :create_if_missing
    source url
  end
end

bash "install-mediaflux" do 
  not_if { ::File.exists?("#{mflux_home}/PACKAGE.MF") }
  user mflux_user
  code <<-EOH
java -jar #{mflux_home}/installer.jar nogui << EOF
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

# Ermm ... there's a security issue with putting the "rc" file here ...
template "#{mflux_user_home}/.mfluxrc" do 
  owner mflux_user
  mode 0600
  source "mfluxrc.erb"
  variables({
    :admin_password => node['mediaflux']['admin_password']
  })
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

template "#{mflux_user_home}/bin/mediaflux" do 
  owner mflux_user
  mode 0755
  source "daris-init.erb"
  variables({
    :mflux_user => mflux_user,
    :mflux_user_home => mflux_user_home
  })
end

template "/etc/init.d/mediaflux" do 
  owner "root"
  mode 0755
  source "daris-init.erb"
  variables({
    :mflux_user => mflux_user,
    :mflux_user_home => mflux_user_home
  })
end

if ! have_license
  # This is as far as we can go without a license file ... 
  log "Please copy your MediaFlux license file to " +
      "#{mflux_home}/config/license.xml and then rerun this recipe" do
    level :fatal
  end
end

# Install license file if it isn't already installed
bash "copy-license" do
  code "cp #{mflux_user_home}/license.xml #{mflux_home}/config/license.xml" +
       " && chmod 444 #{mflux_home}/config/license.xml"
  creates "#{mflux_home}/config/license.xml"
  not_if { ::File.exists?("#{mflux_home}/config/license.xml") }
end

service "mediaflux" do
  action [ :enable, :start ]
end
