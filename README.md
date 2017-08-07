# Fluent::Plugin::SyslogTls

[![Gem Version](https://badge.fury.io/rb/fluent-plugin-syslog-tls.svg)](http://badge.fury.io/rb/fluent-plugin-syslog-tls)

A [Fluentd](http://fluentd.org) output plugin to send logs to various Syslog collectors using TLS (only).

Tested with [Papertrail](https://papertrailapp.com) and should also work with [Sumologic](https://www.sumologic.com/) and likely others.


## Installation

```sh
$ gem install fluent-plugin-syslog-tls
```
or
```sh
$ td-agent-gem install fluent-plugin-syslog-tls
```

Note: `fluent-plugin-syslog-tls` is compatible with Fluent 0.14. For Fluent 0.12, see the `fluent-0.12` branch.


## Configuration

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


## Origin/History

This plugin is derived from [Fluent::Plugin::SumologicCloudSyslog](https://github.com/acquia/fluent-plugin-sumologic-cloud-syslog). Changes are in the [Changelog](CHANGELOG.md).


## License

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

