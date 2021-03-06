#
# Cookbook Name:: mediaflux
# Recipe:: logwatch
#
# Copyright (c) 2014, The University of Queensland
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the The University of Queensland nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
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

#
# Add logwatch config files for Mediaflux, if logwatch is installed.
#
if File.exists?("/etc/logwatch") then
  # Logwatching for the mediaflux backups.
  cookbook_file "/etc/logwatch/scripts/services/mediaflux-backup" do
    source "logwatch-mediaflux-backup-script"
    mode 0755
  end

  cookbook_file "/etc/logwatch/conf/services/mediaflux-backup.conf" do
    source "logwatch-mediaflux-backup-service"
  end
  
  cookbook_file "/etc/logwatch/conf/logfiles/mediaflux-backup.conf" do
    source "logwatch-mediaflux-backup-logfile"
  end

  # Logwatching for other mediaflux logfiles (except for http.log)
  cookbook_file "/etc/logwatch/scripts/services/mediaflux" do
    source "logwatch-mediaflux-script"
    mode 0755
  end

  cookbook_file "/etc/logwatch/conf/services/mediaflux.conf" do
    source "logwatch-mediaflux-service"
  end
  
  cookbook_file "/etc/logwatch/conf/logfiles/mediaflux.conf" do
    source "logwatch-mediaflux-logfile"
  end
end
