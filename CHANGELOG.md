#### 1.1.0

* Renamed `cert` and `key` to `client_cert` and `client_key` respectively.
* Change to short timeouts on network calls so logging doesn't go dead for extended periods.


#### 1.0.0

* Standard fluent formatting plugins are supported. Json output remains the default.
* `token` (Structured Data in syslog terms) is now optional, for syslog hosts that don't require it.
* Message payload in the syslog packet no longer duplicates Time or includes Tag by default.


#### < 1.0.0
From [Fluent::Plugin::SumologicCloudSyslog](https://github.com/acquia/fluent-plugin-sumologic-cloud-syslog)
