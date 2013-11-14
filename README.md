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

Recipes
=======

* `mediaflux::default` - installs the Mediaflux server and utilities.
* `mediaflux::aterm` - installs just the Mediaflux "aterm" utility.
* `mediaflux::aar` - installs just the Mediaflux "aar" utility.


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
* `node['mediaflux']['host']` - The server's hostname.  If unspecified,  this defaults to name or IP address for this host.
* `node['mediaflux']['http_port']` - Specifies the port for the Mediaflux server's http listener.  If unset, the server won't start an http listener.
* `node['mediaflux']['https_port']` - Specifies the port for the Mediaflux server's https listener.  If unset, the server won't start an https listener.  Note that for https to work, you also need to create or obtain a suitable SSL certificate.  The recipe will bail out if a certificate is required and none is available; e.g. in the 'installers' directory.
* `node['mediaflux']['run_as_root']` - If true, the server will be run as "root" allowing it to bind to the normal HTTP / HTTPS ports.
* `node['mediaflux']['install_java']` - If true, the main recipe will attempt to install Java using the "java::default" recipe.  
* `node['mediaflux']['java_command']` - The pathname to be used for the Java command.  If this is unset, the platform-specific default path for the "java" command is used.
* `node['mediaflux']['server_name']` - The name of the DaRIS server
* `node['mediaflux']['server_organization']` - The organization string for the server
* `node['mediaflux']['mail_smtp_host']` - The mail relay host for sending mail.
* `node['mediaflux']['mail_smtp_port']` - The corresponding port.
* `node['mediaflux']['mail_from']` - The "from:" address for regular mail sent by the server.
* `node['mediaflux']['notification_from']` - The "from:" address for notifications.
* `node['mediaflux']['authentication_domain']` - A Mediaflux authentication domain name for users.  This defaults to the namespace prefix.  If it is different, then you will most likely need to "tweak" some of the ${ns}_pssd package TCL code. 
* `node['mediaflux']['jvm_memory_max']` - The server's heap size (in Mbytes)
* `node['mediaflux']['jvm_memory_perm_max']` - The server's permgen size (in Mbytes)

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

You could take further steps to secure the admin password.  However, note that 
obfuscating or encrypting with a hard-wired key only gives the illusion of
security ... if the attacker can gain root access to the machine.

Tools and RC files
==================

These recipes install a server init file, and some scripts for doing admin
tasks:

* The "mediaflux" script is the Mediaflux server's init script.

* The "aterm" script is a wrapper for launching the Mediaflux aterm shell.

* The "mfcommand" script is a modified version of the standard Mediaflux 
  mfcommand script.

* The "change-mf-password.sh" script automates the procedure for changing 
  the Mediaflux admin password.

Rather than embedding configuration parameters directly into the scripts, we
use a simple system of "rc" files.  These are essentially shell scripts that
set environment variables and are designed to be "sourced" by the main scripts.
The system-wide "rc" files live in the "/etc/mediaflux" directory.

The "/etc/mediaflux/mfluxrc" defines public parameters:
  * `MFLUX_HOST` gives the server's hostname or IP address
  * `MFLUX_PORT` gives the server's preferred port number
  * `MFLUX_TRANSPORT` gives the server's preferred connection scheme
  * `MFLUX_HOME` gives the Mediaflux installation directory
  * `MFLUX_BIN` gives the directory where Mediaflux (and related) commands are
    installed.
  * `MFLUX_JAVA` gives the pathname of the "java" command that the various
    scripts will use.

* The "/etc/mediaflux/servicerc" defines some additional private parameters.  
  * `MFLUX_SYSTEM_USER` gives the service account name for running the service.
  * `MFLUX_DOMAIN`, `MFLUX_USER` and `MFLUX_PASSWORD` give the credentials for
    a mediaflux account.  (For the init script, this needs to be the Mediaflux
    admin account.  In other contexts, this could be an upload user's account,
    or the end user's account.) 
  * `MFLUX_JAVA_OPTS` gives the server's JVM options.

Since the servicerc file contains admin authorization credentials, it should 
be owned by "root:root" and not world readable or writeable.  (If this is not
sufficiently secure, consider using SELinux or similar to further limit 
access.)

Typical scripts will / should "source" this file to pick up the default settings
for the corresponding variables; e.g.

    if [ -r /etc/mediaflux/mfluxrc ] ; then
        . /etc/mediaflux/mfluxrc
    fi

Depending on the nature of the script, it may also be appropriate to source an
"rc" file from the user's home directory.

    if [ -r $HOME/.mfluxrc ] ; then
        . $HOME/.mfluxrc
    fi

But if you do this, and the file contains passwords then you / your users need 
to take appropriate steps to secure the users' "rc" files.

Differences from standard and DaRIS Mediaflux
=============================================

The differences are pretty minor, but worth noting.

* The standard Mediaflux installation assumes that the mediaflux user's home
  directory and the installation directory are the same.  With this recipe, 
  they default to different locations.

* In a standard Mediaflux installation, the mediaflux init script reads config
  variables from /etc/mediaflux.  With this recipe, /etc/mediaflux is a 
  directory, and the variables are defined in /etc/mediaflux/mfluxrc
  and /etc/mediaflux/servicerc.

* In a standard Mediaflux installation, there is no "aterm" wrapper, and no
  "change-mf-password" script.  Changing the admin password is a manual
  procedure using "aterm" and a text editor to edit the /etc/mediaflux file.

* In a standard Mediaflux installation, the "mfcommand" wrapper doesn't use an
  "rc" file to pick up configuration variables.

* In a standard Mediaflux installation, the server is launched as "root".  
  With this recipe, the default behaviour is to launch as the Mediaflux user.

* In a vanilla DaRIS Mediaflux installation (i.e. when you follow the DaRIS 
  installation instructions), the init script reads the ".mfluxrc" file in
  the Mediaflux user's home directory.  This is a potential security hole.

* In a vanilla DaRIS Mediaflux installation, the admin password is obfuscated 
  by base64 encoding it.  This only gives an illusion of security so we have
  eliminated that.

TO-DO LIST
==========

* Creation / installation of a self-signed certificate.  Could use the LWRP 
resource that is being added to the standard "openssl" cookbook in 
https://tickets.opscode.com/browse/COOK-847.



