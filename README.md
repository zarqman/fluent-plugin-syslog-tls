# Fluent::Plugin::SumologicCloudSyslog

[![Gem Version](https://badge.fury.io/rb/fluent-plugin-sumologic-cloud-syslog.png)](http://badge.fury.io/rb/fluent-plugin-sumologic-cloud-syslog)
[![Build Status](https://travis-ci.org/acquia/fluent-plugin-sumologic-cloud-syslog.png?branch=master)](https://travis-ci.org/acquia/fluent-plugin-sumologic-cloud-syslog)
[![Coverage Status](https://coveralls.io/repos/acquia/fluent-plugin-sumologic-cloud-syslog/badge.png)](https://coveralls.io/r/acquia/fluent-plugin-sumologic-cloud-syslog)

A [Fluentd](http://fluentd.org) plugin to send logs to the [Sumologic](https://www.sumologic.com/) Cloud Syslog collectors.


## Installation
---
```sh
$ gem install fluent-plugin-sumologic-cloud-syslog
```
or
```sh
$ td-agent-gem install fluent-plugin-sumologic-cloud-syslog
```


## Configuration
---
In your Fluentd configuration, use `@type sumologic_cloud_syslog`. An example configuration would be:

```
<match **>
  @type sumologic_cloud_syslog
  host syslog.collection.us1.sumologic.com
  port 6514
  token 'YOUR-PRIVATE-TOKEN@IANA-ID'
</match>
```

For more configuration options see [configuration docs](docs/configuration.md)

### Puppet

If you are using Puppet for configuration management then an example configuration
using the [wywygmbh/puppet-fluentd](http://github.com/wywygmbh/puppet-fluentd) puppet module would be:

```
::fluentd::plugin { 'fluent-plugin-sumologic-cloud-syslog':
  type => 'gem',
}

::fluentd::match { 'sumologic_cloud_syslog':
  priority => 10,
  pattern  => '**',
  config   => {
    'type'  => 'sumologic_cloud_syslog',
    'host'  => 'syslog.collection.us1.sumologic.com',
    'port'  => 6514,
    'token' => $token,
    'cert'  => $cert,
    'key'   => $key,
  },
}
```

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

