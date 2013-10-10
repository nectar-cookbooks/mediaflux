Overview
========

This cookbook is for installing and doing the initial configuration of a
MediaFlux instance.  The prerequisites are the installation files 
for MediaFlux,and a current license key file for MediaFlux:

  - The MediaFlux installation JAR file and license key should be obtained
    from Architecta (or SGI who distribute it as "LiveArc").

Dependencies
============

MediaFlux is a Java application, and this cookbook uses the OpenJDK Java 7 JDK
to fulfill this dependency.  If you want to, you can set node attributes to
override the defaults; see the http://community.opscode.com/cookbooks/java for
the relevant attributes

This cookbook should in theory be platform independent ... across unix-like 
OSes.  The service installation stuff is one aspect that is guaranteed to not
work on Windows.

Attributes
==========

See `attributes/default.rb` for the default values.

* `node['mediaflux']['home']` - Specifies the installation directory for Mediaflux.
* `node['mediaflux']['user']` - Specifies the MediaFlux system username.
* `node['mediaflux']['user_home']` - Specified the MediaFlux system user's home directory.
* `node['mediaflux']['fs']` - Specifies a data directory for the Mediaflux server.  If this directory exists, the recipe will make the Mediaflux "volatile" directory a symlink to this one, and populate it with the required subdirectories.
* `node['mediaflux']['installer_url']` - Specifies a URL for downloading the Mediaflux installer.  By default this is "unset", and the recipe will assume that you have obtained and placed the installer in "#{node['mediaflux']['home']}/installer.jar".
* `node['mediaflux']['admin_password']` - Specifies the initial "encrypted" MediaFlux administrator password.  The `DaRIS installation instructions explain how to encrypt a password, and how to change the password post-installation.
* `node.default['mediaflux']['http_port']` - Specifies the port for the MediaFlux server's http listener.  If unset, the server won't start an http listener.
* `node.default['mediaflux']['https_port']` - Specifies the port for the MediaFlux server's https listener.  If unset, the server won't start an https listener.  Note that for https to work, you also need to create or obtain a suitable SSL certificate.  
