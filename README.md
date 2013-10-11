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
* `node.default['mediaflux']['run_as_root']` - If "true", the server will be run as "root" allowing it to bind to the normal HTTP / HTTPS ports.

Configuring the ports
=====================

The recipe defaults to running the mediaflux service as the (non-privileged)
mediaflux user, and using high-end ports (8080 / 8443).  This is done for 
security reasons.  (Running the service as "root" would be a security risk,
and Java applications cannot do the normal trick of binding to sockets and
then lowering their access.)

If you need your service to be accessible on the standard ports (80 / 443), 
you have the following choices:

* Use "iptables" (or equivalent) to redirect external traffic from port 80
  to port 8080, and from port 443 to 8443.  Details of how you do this will
  be system specific, though there are community cookbooks that might help.

* Implement a front-end web server that listens on ports 80 / 443, and 
  reverse-proxies mediaflux traffic to high-end ports.  If you do this for
  port 443, then you need to arrange (somehow) that the reverse proxied 
  traffic uses a loopback IP address ... because connections won't be 
  secured and encrypted, end-to-end.

* If you are running on a Debian or Ubuntu based system, you may be able to
  use the "authbind" utility to allow the mediaflux to bind to ports 80 and 
  443; for example, see http://www.jvmhost.com/articles/java-net-bindexception-permisssion-denied-operation-not-permitted.

* Ignore the security concerns, and set the "run_as_root" attribute to "true".
  This approach is not recommmended!
