Note: v0.5+ is compatible with Fluent 0.12. Use v1.0+ with Fluent 0.14.

#### 0.6.0
* Backport `ca_cert` from master to fluent-0.12 branch
  - Added `ca_cert` to validate the remote certificate. Defaults to 'system' which uses the system certificate store.


#### 0.5.0

Comparable to 1.0.0 from [master (Fluent 0.14) branch](https://github.com/zarqman/fluent-plugin-syslog-tls).

* Standard fluent formatting plugins are supported. Json output remains the default.
* `token` (Structured Data in syslog terms) is now optional, for syslog hosts that don't require it.
* Message payload in the syslog packet no longer duplicates Time or includes Tag by default.


#### < 0.2.0

From [Fluent::Plugin::SumologicCloudSyslog](https://github.com/acquia/fluent-plugin-sumologic-cloud-syslog)
