Instructions on how to setup a Vagrant test instance of Mediaflux
=================================================================

Prerequisites
-------------

You need a Mediaflux license file for your test instance.  Ask Arcitecta.

You need Vagrant and the supporting stuff installed on your dev machine.

You need to have created a Vagrant instance, and provisioned it with Chef-solo and Berkshelf.

You need to check that the MAC address for the vagrant instance (still) matches the MAC address for your license file.

Template node JSON file
-----------------------

This template is suitable for mediaflux testing on a vagrant instance whose hostname is "precise32".

```
{
  "name": "test",
  "chef_environment": "_default",
  "mediaflux": {
     "installer_url": "http://www.arcitecta.com/...",
     "installer" : "mflux-dev_3.8.050_jvm_1.6.jar",
     "server_organization": "...",
     "mail_smtp_host": "localhost",
     "mail_from": "mediaflux@precise32",
     "notification_from": "do-not-reply@precise32",
     "authentication_domain": "users",
     "volatile": "/mnt/mf-volatile",
     "accept_license_agreement": true,
     "backup_cron": true,
     "backup_cron_email": "vagrant"
  },
  "daris": {
     "release": "latest",
     "local_pkgs" : {
        "your_pssd": "mfpkg-your_pssd....zip"
     },
     "ns": "cai",
     "dicom_proxy_domain": "dicom",
     "dicom_ingest_notifications" : [ "vagrant@precise32" ],
     "force_bootstrap": false,
     "user_groups": ["...", "..."]
  },
  "setup": {
    "tz": "Australia/Brisbane",
    "set_fqdn": "precise32",
    "logwatch": true,
    "antivirus": false,
    "accounts": {
      "create_users": true
    }
  },
  "run_list": [
    "recipe[setup]",
    "recipe[mediaflux]",
    "recipe[daris]",
    "recipe[daris::users]",
    "recipe[daris::dicom-hosts]"
  ]
}
```