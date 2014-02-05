#
# Cookbook Name:: mediaflux
# Recipe:: backups
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

mflux_home = node['mediaflux']['home']
mflux_bin = "#{mflux_home}/bin"
mflux_config = "#{mflux_home}/config"
mflux_user = node['mediaflux']['user']

# Note that we take a copy of the 'stores' array ... so that downstream
# recipes can inject their own store names into the list via the template
# resource
mflux_stores = Array.new(node['mediaflux']['stores'] || [])

backup_dir = node['mediaflux']['backup_dir'] || "#{mflux_home}/volatile/backups"
replica = node['mediaflux']['backup_replica'] || ''
object_store = node['mediaflux']['backup_store'] || ''
keep_days = node['mediaflux']['backup_keep_days'] || 5

directory backup_dir do
  owner mflux_user
  group mflux_user
  mode 0750
end

if object_store != '' then
  node.normal['setup']['openstack_rc_path'] = '/etc/mediaflux/openstackrc'
  node.normal['setup']['openstack_rc_group'] = mflux_user
  include_recipe 'setup::openstack-clients'
end

template "backup.sh" do
  path "#{mflux_home}/bin/backup.sh"
  source 'backup_sh.erb'
  owner mflux_user
  mode 0700
  variables ({
               'backup_dir' => backup_dir,
               'replica' => replica,
               'object_store' => object_store,
               'keep_days' => keep_days
             })
end

external_asset_backup = node['mediaflux']['external_asset_backup']
backup_wrapper = node['mediaflux']['backup_wrapper']
if ! /^\/.+/ then
  backup_wrapper = "#{mflux_bin}/#{backup_wrapper}"
end

template "backup.tcl" do
  path "#{mflux_config}/backup.tcl"
  source 'backup_tcl.erb'
  owner mflux_user
  mode 0600
  variables ({
               'stores' => mflux_stores,
               'external_asset_backup' => external_asset_backup,
               'backup_wrapper' => backup_wrapper
             })
end

wrappers = ['tar_gz_wrapper']
wrappers.each do |wrapper|
  cookbook_file "#{mflux_bin}/#{wrapper}" do
    source wrapper
    mode 0555
    owner mflux_user
    group mflux_user
  end
end

times = node['mediaflux']['backup_cron_times']
mailto = node['mediaflux']['backup_cron_mailto']
if node['mediaflux']['backup_cron'] then
  if mailto && mailto != '' then
    cron 'mediaflux_backup_cron' do
      command "#{mflux_home}/bin/backup.sh"
      minute times[0]
      hour times[1]
      day times[2]
      month times[3]
      weekday times[4]
      user mflux_user
      mailto mailto
    end
  else
    cron 'mediaflux_backup_cron' do
      command "#{mflux_home}/bin/backup.sh"
      minute times[0]
      hour times[1]
      day times[2]
      month times[3]
      weekday times[4]
      user mflux_user
    end
  end
end
