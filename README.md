Overview
========

This cookbook is for installing and doing the initial configuration of a
Mediaflux instance.  The prerequisites are the installer
for Mediaflux, and a current license key file for Mediaflux.  You are also
required to accept the Mediaflux license.

* The Mediaflux installer and a Mediaflux license key should be obtained 
  from Architecta (or from SGI who distribute it as "LiveArc").  See below
  for details.
  * The installer can be downloaded by hand and placed in the "installers"
    directory, setting its filename in the 'installer' attribute.
    Alternatively, you can set the 'installer_url' attribute (giving the
    full URL), or 'download_base_url' and either 'version' or 'installer'.
    Details are below: see "Specifying the Mediaflux Installer to use".
  * The license file must be placed in the installer directory by hand.
    
* When you run the Mediaflux installer, you are required to accept the
  Mediaflux license agreement before it will proceed.
  * You can run the installer manually to allow you to read and accept
    the license.
  * Alternatively, you can set the `mediaflux.accept_license_agreement`
    attribute to signify that you accept the agreement ... before running
    the recipes.

Dependencies
============

Mediaflux is a Java application, and this cookbook uses the OpenJDK Java 7 JDK
to fulfill this dependency.  If you want to, you can set node attributes to
override the defaults; see the http://community.opscode.com/cookbooks/java for
the relevant attributes.

The recipes in this cookbook should work on x86 and x86-64 systems running
recent Ubuntu, RHEL compatible and Fedora distros (at least).  Windows is
is not supported.

If you enable saving backups to a SWIFT object store (see below), you need
to make sure that `node['setup']['openstack_clients']` is false.  The 
"mediaflux::default" recipe needs to run the "setup::openstack-clients" 
recipe itself ... after tweaking some attributes.  (See issue #2).

Recipes
=======

* `mediaflux::default` - installs the Mediaflux server and all utilities, and sets up backups.
* `mediaflux::aterm` - installs just the Mediaflux "aterm" and "mfcommand"
  utilities.
* `mediaflux::aar` - installs just the Mediaflux "aar" utility.
* `mediaflux::test_cert` - generates a self-signed cert suitable for testing (only)
* `mediaflux::backups` - sets up Mediaflux backups.

Attributes
==========

See `attributes/default.rb` for the default values.

* `node['mediaflux']['home']` - Specifies the installation directory for Mediaflux.
* `node['mediaflux']['bin']` - Specifies the directory for installing "Mediaflux related" utilities.  This defaults to the bin subdirectory of the installation directory.
* `node['mediaflux']['user']` - Specifies the Mediaflux system username.
* `node['mediaflux']['user_home']` - Specified the Mediaflux system user's home directory. This defaults to the installation directory.
* `node['mediaflux']['volatile']` - Specifies a data directory for the Mediaflux server.  If this directory exists, the recipe will make the Mediaflux "volatile" directory a symlink to this one, and populate it with the required subdirectories.
* `node['mediaflux']['installers']` - Specifies a local directory where the recipes will look for downloaded installers and license files.
* `node['mediaflux']['installer']` - Specifies the (simple) filename for the Mediaflux installer.  By default this is unset.
* `node['mediaflux']['version']` - Specifies the Mediaflux version number; e.g. ".  By default this is unset (nil).
* `node['mediaflux']['installer']` - Specifies the (simple) filename for the Mediaflux installer.  By default this is unset.
* `node['mediaflux']['installer_url']` - Specifies the full URL for downloading the specific Mediaflux installer.  By default this is unset (nil).
* `node['mediaflux']['download_base_url']` - Specifies the base URL for downloading the specific Mediaflux installer.  By default this is unset (nil).
* `node['mediaflux']['accept_license_agreement']` - Set this to true to signify that you accept the Mediaflux license agreement embedded in the installer.
* `node['mediaflux']['on_version_mismatch']` This tells the recipe what to do if it detects that the currently installed Mediaflux is different to the requested version.  The default value is 'fail'.  See the Upgrading section for details of the other settings.
* `node['mediaflux']['host']` - The server's hostname.  If unspecified,  this defaults to `'localhost'`.
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
* `node['mediaflux']['backup_dir']` - The primary location where backups are saved.  This defaults to the "$MFLUX_HOME/volatile/backups".
* `node['mediaflux']['backup_replica']` - The location for the rsync backup replica.  If unset, there is no rsync replication.
* `node['mediaflux']['object_store']` - The Swift Object Store storename for saving backups.  See below for details.  If unset, backups are not saved to Swift.
* `node['mediaflux']['backup_keep_days']` - Keep backups for this many days. 
* `node['mediaflux']['backup_keep_sets']` - Keep this number of backups sets. 
* `node['mediaflux']['backup_cron']` - If true, a cron job is created to run the backups.  Defaults to false.
* `node['mediaflux']['backup_cron_mailto']` - Mail account for backup cron email.
* `node['mediaflux']['backup_cron_times']` - The backup cron schedule.  Defaults to `[ "0", "2", "*", "*", "*" ]`.
* `node['mediaflux']['stores']` - This lists the Mediaflux stores to be backed up.  (Downstream recipes may inject additional stores dynamically; see below.)
* `node['mediaflux']['external_asset_backup']` - This determines whether stores are backed up using Mediaflux `asset.archive.create` or by running an external backup wrapper.  Defaults to true (for now) due to issues with Mediaflux the `asset.archive.*` services.
* `node['mediaflux']['backup_wrapper']` - This gives the name of the external backup wrapper command.  See below for details. Defaults to "tar_gz_wrapper".

Specifying the Mediaflux Installer to use
=========================================

As mentioned above, you need to obtain an installer for Mediaflux (together
with a license file).  Mediaflux installers are available from Mediaflux
from the Mediaflux download site.  Unfortunately (for us) Mediaflux
would prefer the site's URL to not be disclosed in this Cookbook.  To cater 
for this, we have devised a "scheme" in which you have three options for 
downloading the installer:

 1. You can specify the full URL of the downloadable in the 'installer'
    attribute.

 1. You can specify a base URL for the downloads in the 'download_base_url'
    and either a 'version' or a 'installer' to select the specific 
    downloadable.  (Hint: the base URL consists of a hostname and pathname
    components that do not include version information.  Or look at what
    the recipes actually do.)

 1. You can download the installer by hand, and place it in the designated
    local installer cache directory; e.g. "/opt/mediaflux_installers".  If 
    you do this, you need to set either 'installer' or 'version' to correspond
    to the installer you want to use.

The recipes will try only one option to getting the installer, depending 
on what attributes are set, but they are considered in the order above.  If
extra attributes are set, the recipe will do some consistency checks.

Please note:
 
 * The recipe requires the filename of the original installer to be preserved 
   for correct operation.

 * If you are using DaRIS, you need to select a version of Mediaflux that
   satisfied the requirements of your DaRIS version.  This is not currently
   checked.

Upgrading Mediaflux
===================

The recipe will not automatically upgrade the Mediaflux install.  Instead,
the default behaviour is to check the currently installed Mediaflux version 
against the requested version, and **fail** if they are not the same.  This
behaviour can be modified via the 'on_version_mismatch' attribute:

 * `fail` causes the recipe to fail.
 * `warn` causes the recipe to output a "loud" warning, and continue.  The 
   Mediaflux installation is not modified.
 * `upgrade` causes the recipe to do an in-place reinstall of Mediaflux,
   provided that the requested version is newer than the current version.
   If the requested version is older, the recipe fails.
 * `force_reinstall` causes in in-place reinstall, irrespective of the 
   versions.

Note that there is a risk that a reinstall could break an existing installation
and / or damage the Mediaflux database and data stores.
   
**Make sure that your backups are up to date before you upgrade!**

And when you are finished upgrading, remember to change the 'on_mismatch' 
attribute back to 'fail' ... to prevent accidents!

Java installation details
=========================

If the `node['mediaflux']['install_java']` is true, then the "mediaflux"
cookbook will use the "java" cookbook to install Java.  The `node['java']`
attributes will determine the flavour and version of Java that is selected.
Some of these are overridden at the default level by the "mediaflux" cookbook.

Arcitecta recommend that you use the latest Oracle 1.7.x Java; 
see https://groups.google.com/forum/#!topic/mediaflux/Tn1ryG59lwU.  However, 
there is a "gotcha".  The "java" cookbook relies on a patch-specific download 
URL and checksum to select the version of Oracle Java.  By default, these are
provided by attribute defaults.  This means that if you select "oracle" 
flavour, your system's Java installation does not get updated automatically 
... which is not a good thing.  By constrast, the "openjdk" flavour will 
keep your system up-to-date with the latest patch release of Java available 
from the distro's repositories.

Accordingly, the "mediaflux" cookbook defaults to specifying the "openjdk" 
flavour of Java.

The "java" cookbook plugs the installed Java into the "alternatives" system 
so that the commands are available via the normal distro-specific paths.  The
"mediaflux" cookbook assumes this.  If you want to use a different Java 
installation, set `node['mediaflux']['install_java']` to the path to the
`java` command.

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

Confidence testing
==================

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
  mfcommand script, which is in turn a commandline version of aterm.

* The "aar" script is a wrapper for the Mediaflux aar archive tool.

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
  * `MFLUX_JAVA_OPTS` gives JVM options for use by tools.

* The "/etc/mediaflux/servicerc" defines some additional private parameters.  
  * `MFLUX_SYSTEM_USER` gives the service account name for running the service.
  * `MFLUX_DOMAIN`, `MFLUX_USER` and `MFLUX_PASSWORD` give the credentials for
    a mediaflux account.  (For the init script, this needs to be the Mediaflux
    admin account.  In other contexts, this could be an upload user's account,
    or the end user's account.) 
  * `MFLUX_JAVA_OPTS` gives the server's JVM options.  (This overrides the
    `MFLUX_JAVA_OPTS` variable in the 'mfluxrc' file.)

Since the 'servicerc' file contains admin authorization credentials, it should 
be owned by "root:root" and not be world readable or writeable.  (If this is not
sufficiently secure, then consider using SELinux or similar to further limit 
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

Backups
=======

This recipe creates a simple backup script that can be used to backup the
Mediaflux database and the assets in the respective stores.  The script is 
designed for performing a full backups (at most) once a day, keeping 
backup sets for either N days, or keeping the N most recent sets.

* The actual backups are performed by running a Mediaflux TCL script that write the files to the primary backup location.
* Backups are optionally "replicated" to another location using `rsync`.
* Backups are optionally saved to a Swift object store.
* Logs of what the backup script does are written to "backups.log" in the Mediaflux log directory.

The recipe will optionally create a cron job to run the backups.  You can specify the schedule for the job, and an optional email address for mailing failure reports to.

Creating the backups
--------------------

The backups are created by a Mediaflux TCL script.  The standard version of
this script first uses the Mediaflux 'system.database.backup' service to 
create a backup of the primary Mediaflux database.  Then if backs up each 
of the Mediaflux stores in the `stores` list by running 
'assets.archive.create' for the store, or using 'exec' to launch an 
external backup wrapper.

Backup wrappers are external applications (e.g. shell scripts) that take two 
command-line arguments.  

* The first argument is the (absolute) pathname for the directory into which 
backup files should be written.  (The pathname typically includes the current
date, or something else to denote the backup in the backup cycle.)
* The second argument is the simple name of the Mediaflux store.

Standard backup wrappers are placed in the Mediaflux `bin` directory, and
are generated from recipe templates.  However, you are free to create your
own backup wrapper by hand; e.g. copying the pattern of the existing 
`tar_gv_wrapper`.  If you do this, provide the full pathname for the 
wrapper as `external_backup_wrapper`.

Replicating the backups using "rsync"
-------------------------------------

The backup script can maintain replica of the backup tree consisting of all
backup sets that are being "kept"; see above.  The replication is done by using
`rsync` to sync the files to a local or remote location given by the 
"backup_replica" attribute.  For example:

* If (say) an RDSI collection was mounted as "/data/Qxxxx", you could save the backups there by using "/data/Qxxxx/backups" as the location.
* If you have set up the appropriate SSH credentials, you could save backups remotely using "somehost.example.com:/backups".

Saving backups to a Swift object store
--------------------------------------

(This is currently specific to NeCTAR, but it could be generalized)

The backup can save copies of backups in a Swift object store.  In order to
make this work, you need to install the "swift" client and set up appropriate
authentication credentials for accessing them in "/etc/mediaflux/openstackrc".
This can be done by hand, or by setting the appropriate attributes and adding 
the "qcloud::setup" or "qcloud::openstack_clients" recipe to your node's
run-list.  Refer to the "qcloud" cookbook documentation.

Note that the "mediaflux::default" recipe overrides
`node['qcloud']['openstack_rc_path']` to put the credentials file in the
location above.

Restoring backups
-----------------

The procedure for reconstructing a Mediaflux instance from backups is roughly
as follows:

1.  If there is any possibility that you might want to recover data from the
    existing (possibly damaged) Mediaflux instance, save the existing 
    installation, including everything in the `volatile` tree.  (If you have
    `volatile` as a symlink to another disk area, then make sure that you
    save that as well.

    If you have sufficient spare disc space, simply use the `mv` command to
    rename the respective trees out of the way.  Otherwise "archive, compress 
    and copy" using standard utilities.

2.  Use `mkdir` to create clean directories for the Mediaflux installation
    and the target of the `volatile` symlink.

3.  Use chef-solo to run the recipes for building your Mediaflux (etc) 
    installation.

4.  Start an `aterm` session using the admin account.

5.  Restore the database by running the Mediaflux command 

        service.database.restore :url file:///..../database

    where the url refers to a local copy of the database backup.

6.  For each store:

    * If you used `asset.archive.create`, then use 

            asset.archive.restore :url file:///..../<storeName>.aar \
                    :restore-missing-content true
      
      to restore the assets.  Note: this won't work with older versions 
      of Mediaflux that don't support that option.

    * If you used an external backup wrapper, use the corresponding
      utility to restore the files from the backup into the file 
      system directory or the store (i.e. `.../volatile/stores/<storeName>`). 

Once this is done, use your portal software and attempt to access some assets
to check that files have indeed been restored in the correct place.

Differences between this, standard Mediaflux and DaRIS Mediaflux
================================================================

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
  eliminated that.  (If that concerns you / your local security folk, open an
  issue and I'll see what we can do.)
