Overview
========

This cookbook is for installing and doing the initial configuration of a
Mediaflux instance.  The prerequisites are the installation files 
for Mediaflux,and a current license key file for Mediaflux:

  - The Mediaflux installation JAR file and license key should be obtained
    from Architecta (or SGI who distribute it as "LiveArc").

Dependencies
============

Mediaflux is a Java application, and this cookbook uses the OpenJDK Java 7 JDK
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
* `node['mediaflux']['bin']` - Specifies the directory for installing "Mediaflux related" utilities.  This defaults to the bin subdirectory of the installation directory.
* `node['mediaflux']['user']` - Specifies the Mediaflux system username.
* `node['mediaflux']['user_home']` - Specified the Mediaflux system user's home directory. This defaults to the installation directory.
* `node['mediaflux']['volatile']` - Specifies a data directory for the Mediaflux server.  If this directory exists, the recipe will make the Mediaflux "volatile" directory a symlink to this one, and populate it with the required subdirectories.
* `node['mediaflux']['installers']` - Specifies a local directory where the recipes will look for downloaded installers and license files.
* `node['mediaflux']['installer']` - Specifies the (simple) filename for the Mediaflux installer.
* `node['mediaflux']['installer_url']` - Specifies a URL for downloading the Mediaflux installers.  By default this is unset (nil), and the recipe will assume that you have obtained and placed the installer in the 'installers' directory.
* `node.default['mediaflux']['http_port']` - Specifies the port for the Mediaflux server's http listener.  If unset, the server won't start an http listener.
* `node.default['mediaflux']['https_port']` - Specifies the port for the Mediaflux server's https listener.  If unset, the server won't start an https listener.  Note that for https to work, you also need to create or obtain a suitable SSL certificate.  The recipe will bail out if a certificate is required and none is available; e.g. in the 'installers' directory.
* `node.default['mediaflux']['run_as_root']` - If true, the server will be run as "root" allowing it to bind to the normal HTTP / HTTPS ports.
* `node.default['mediaflux']['install_java']` - If true, the main recipe will attempt to install Java using the "java::default" recipe.  
* `node.default['mediaflux']['java_command']` - The pathname to be used for the Java command.  If this is unset, the platform-specific default path for the "java" command is used.

The Java installation details are as follows:

* If "install_java" flag is true, then the "java" cookbook attributes determine the version selected.  (Note that these are overridden at the "default" level in the mediaflux "attributes/default.rb" file.)

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

Testing
=======

Once DaRIS is installed, we recommend that you do the following simple tests:

* Check that the Mediaflux service is running using the command "sudo /etc/init.d/mediaflux status".

* Start the "aterm" command shell by running "~mediaflux/bin/aterm".  This is an X11 application, so you will need to enable X11 forwarding if you connect via SSH.

* Establish a browser connection to the root of the Mediaflux web portal.  The URL will be "http://<hostname>:<http-port>/" or "https://<hostname>:<https-port>/".   (If you used a self-signed SSL cert, you will need to tell your browser "it is OK" in the appropriate fashion ...).  Note that you can't do anything useful here, but this will confirm that HTTP / HTTPS connections are working.

* Attempt to use the Daris Portal.
  * Establish a browser connection to the DaRIS portal via https.  The URL will be  "https://<hostname>:<https-port>/daris/".  
  * Login using system/manager and your manager password.  
  * If you are prompted to allow an Architecta Mediaflux DTI agent applet to run, allow it.
  * If you are prompted to allow loading of code from your website, allow it.  (That's most likely due to using a self-signed certificate.)
  * When you get to the DaRIS Portal itself, check that the DTI agent is active.  Look at the "DTI" icon in the menu bar.  If it fails to activate, the DaRIS wiki has a page on "Java Issues" to help you diagnose the problem.  Also look at "
https://<host>:<port>/daris/docs/install-dti.html".

Security issues
===============

The Mediaflux admin password is stored in the "/etc/mediaflux/servicerc" 
file.  This file should be readable only by "root" and the mediaflux user /
group.  (The "mediaflux::default" Chef recipe will return it to that state 
whenever you run it.)

You could take further steps to secure the password.  However, note that 
obfuscating or encrypting with a hard-wired key only gives the illusion of
security ... if the attacker can gain root access to the machine.


Differences from standard Mediaflux
===================================

* The standard Mediaflux installation assumes that the mediaflux user's home
  directory and the installation directory are the same.  With this recipe, 
  they default to different locations.

* In a standard Mediaflux installation, the mediaflux init script reads config
  variables from /etc/mediaflux.  With this recipe, /etc/mediaflux is a 
  directory, and the variables are defined in /etc/mediaflux/mfluxrc
  and /etc/mediaflux/servicerc.

* In a standard Mediaflux installation, there is no "aterm" wrapper.

* In a standard Mediaflux installation, the "mfcommand" wrapper doesn't use an
  "rc" file to pick up configuration variables.

* In a standard Mediaflux installation, the server is launched as "root".  
  With this recipe, the default behaviour is to launch as the Mediaflux user.

Differences from DaRIS Mediaflux
================================

* In a DaRIS Mediaflux installation (i.e. when you follow the DaRIS 
  installation instructions), the init script reads the ".mfluxrc" file in
  the Mediaflux user's home directory.  This is a potential security hole.

* In a DaRIS Mediaflux installation, the admin password is obfuscated by
  base64 encoding it.  This only gives an illusion of security.

TO-DO LIST
==========

* Creation / installation of a self-signed certificate.  Could use the LWRP 
resource that is being added to the standard "openssl" cookbook in 
https://tickets.opscode.com/browse/COOK-847.

* We currently assume that the 'java' on the PATH is the right one to use.

* Installing stuff in ~mediaflux/bin is maybe not the best ...

