Change Log for the Mediaflux cookbook
=====================================
Version 0.9.15
--------------
 - Rework the Mediaflux upgrade support. The 'reinstall' attribute is
   replaced by 'on_version_mismatch'.

Version 0.9.14
--------------
 - Rework the installer selection attributes: Note - you >>may<<
   need to change some attribute values ...

Version 0.9.13
--------------
 - Fix for session timeouts during backups (#27)
 - Fix for database locks left after failed backups (#28)
 - Installer cache now owned by root

Version 0.9.12
--------------
 - Added "--norc" option to the "mfcommand" script

Version 0.9.11
--------------
 - Tracking change in 'setup' cookbook

Version 0.9.10
-------------
 - Fix bug in cycling backups after a failure (#26)

Version 0.9.9
-------------
 - Fix some annoying WARNINGs
 - Fix more tempfile stuff
 - Fix latent bug in handling of backup wrappers

Version 0.9.8
-------------
 - Fix regression with timestamps in logfile (#23)
 - Fix sloppy temp-file handling (#24)

Version 0.9.7
-------------
 - Implement removal of old Swift backup objects (#12)
 - Implement 2nd way of specifying the "keeps".

Version 0.9.6
-------------
 - Cap the computed default max heap size at 4g on 64bit platforms.
 - Fixed typo that was disabling backup to Swift

Version 0.9.5
-------------
 - Support for store backups using an external backup wrapper (issue #20)

Version 0.9.4
-------------
 - Change to generate separate asset archives for each store (issue #18)

Version 0.9.3
-------------
 - Added recipe to generate a self-signed test certificate (issue #16)

Version 0.9.2
-------------
 - Logwatching for other log files
 - Bug fixes for sensing / configuring 32 bit JVMs
 - Allow for the addition of licence.xml and certs files to the installers directory by other recipes
 - Fix problems with the server start/restart "scheduling"

Version 0.9.1
-------------
 - Bug fixes and enhancements to backup logwatching

Version 0.9.0
-------------
 - Added logwatching on the backup logfile

