# Fluent::Plugin::SyslogTls

[![Gem Version](https://badge.fury.io/rb/fluent-plugin-syslog-tls.svg)](http://badge.fury.io/rb/fluent-plugin-syslog-tls)

A [Fluentd](http://fluentd.org) output plugin to send logs to various Syslog collectors using TLS (only).

Tested with [Papertrail](https://papertrailapp.com) and should also work with [Sumologic](https://www.sumologic.com/) and likely others.


## Installation
---
```sh
$ gem install fluent-plugin-syslog-tls -v '~> 0.5'
```
or
```sh
$ td-agent-gem install fluent-plugin-syslog-tls -v '~> 0.5'
```

_Hint: Use v0.5+ for Fluentd 0.12 and v1.0+ for Fluentd 0.14. (See Version Compatibility below.)_


## Configuration
---
In your Fluentd configuration, use `@type syslog_tls`. Examples:

Sumologic:
```
<match **>
  @type syslog_tls
  host syslog.collection.us1.sumologic.com
  port 6514
  token 'YOUR-PRIVATE-TOKEN@IANA-ID'
  format json
</match>
```

Papertrail:
```
<match **>
  @type syslog_tls
  host logs1.papertrailapp.com
  port 12345
  format single_value
</match>
```

For more configuration options see [configuration docs](docs/configuration.md)


## Version Compatibility

* v0.x.x of this plugin is compatible with the Fluentd 0.12 series.
* v1.x.x of this plugin is compatible with the Fluentd 0.14 series.

Note that the v1.x series has more features and is more robust than the v0.x series.


## Origin/History

This plugin is derived from [Fluent::Plugin::SumologicCloudSyslog](https://github.com/acquia/fluent-plugin-sumologic-cloud-syslog). Changes from the original:

* Standard fluent formatting plugins are supported. Json output remains the default.
* `token` (Structured Data in syslog terms) is now optional, for syslog hosts that don't require it.
* Message payload in the syslog packet no longer duplicates Time or includes Tag by default.


## License
---
Except as otherwise noted this software is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

