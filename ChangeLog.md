Change Log for the Mediaflux cookbook
=====================================

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

