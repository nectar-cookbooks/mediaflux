#
# Cookbook Name:: mediaflux
# Recipe:: common
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

##
## Some base configuration that is common to mediaflux server and
## client mc's.  This does not create the mediaflux service user ...
##

mflux_home = node['mediaflux']['home']
mflux_bin = node['mediaflux']['bin'] || "#{mflux_home}/bin"
mflux_user = node['mediaflux']['user']
mflux_host = node['mediaflux']['host'] || 'localhost'

# This is hacky ... and probably wrong for some platforms
if node['mediaflux']['install_java'] then
  include_recipe 'java'
end
java_cmd = node['mediaflux']['java_command'] 
if java_cmd == nil 
  java_cmd = '/usr/bin/java'
end

java_version = `#{java_cmd} -version 2>&1` 
log 'java-version' do
  message "The selected Java command is #{java_cmd} and the " +
          "version is #{java_version}"
  level :debug
end

# General JVM opts to be used by mediaflux clients.
java_opts = node['mediaflux']['client_jvm_opts'] || ''

directory mflux_home do
  owner 'root'
  mode 0755
end

directory "#{mflux_bin}" do
  owner 'root'
  mode 0755
end

directory '/etc/mediaflux' do
  owner 'root'
  mode 0755
end

template '/etc/mediaflux/mfluxrc' do 
  owner 'root'
  mode 0444
  source 'mfluxrc.erb'
  variables({
    :mflux_home => mflux_home,
    :mflux_bin => mflux_bin,
    :mflux_host => mflux_host,
    :http_port => node['mediaflux']['http_port'],
    :https_port => node['mediaflux']['https_port'],
    :java => java_cmd,
    :java_opts => java_opts
  })
end
