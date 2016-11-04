# Configuration

This plugin allows to configure all syslog message attributes.

## Static configuration

Static configuration allow to define connection details, facility and hostname that will
apply to all messages.

### host

Host represents DNS name of endpoint where should be data sent. Example: `syslog.collection.us1.sumologic.com` or `logs1.papertrailapp.com`

### port

Example: `6514`

### token

Some services require a token to identify the account. Example: `ABABABABABABA@99999`. Not required for Papertrail.

### cert

Optionally path to client certificate for TLS connection. Example: `/path/to/crt/file.crt`

### key

Optionally path to client private key for TLS connection. Example: `/path/to/key/file.key`

### hostname

Default hostname that is going to be sent in syslog message. Example: `ip-10-0-0-10`

### facility

Default syslog facility for all records. Example: `LOCAL0`

## Per message configuration

Its possible to configure the plugin to extract various parts of syslog message header
from processed record itself. That allows to dynamically set app_name, procid, msgid from
records if single match is being used to log messages from multiple sources.

### severity_key

Optionally record key where to get severity from the record. If not provided default `INFO` will be used.

### facility_key

Optionally record key where to get syslog facility from the record. If not provided default `LOCAL0` will be used.

### hostname_key

Optionally record key where to get hostname from the record. If not provided hostname is determined by system hostname.

### app_name_key

Optionally record key where to get app_name from the record. If not provided nil value will be sent.

### procid_key

Optionally record key where to get procid from the record. If not provided nil value will be sent.

### msgid_key

Optionally record key where to get msgid from the record. If not provided nil value will be sent.

## Example

This plugin makes use of [Fluent::Mixin::PlainTextFormatter](https://github.com/tagomoris/fluent-mixin-plaintextformatter) please check out its documentation for more configuration options.

```
<match>
  @type syslog_tls
  host logs1.papertrailapp.com
  port 12345

  hostname static-hostname
  facility SYSLOG

  # You can configure syslog headers to be picked from actual message
  # processed by plugin. If key is not provided '-' value will be sent
  # which is NIL by syslog specification.
  severity_key RECORD_SEVERITY_KEY
  facility_key RECORD_FACILITY_KEY
  hostname_key ...
  app_name_key ...
  procid_key ...
  msgid_key ...

</match>
```

```
<match>
  @type syslog_tls
  host syslog.collection.us1.sumologic.com
  port 6514
  token [token]@[iana-id]
  cert /path/to/cert/file.crt
  key /path/to/key/file.key

  hostname static-hostname
  facility SYSLOG

  # You can configure syslog headers to be picked from actual message
  # processed by plugin. If key is not provided '-' value will be sent
  # which is NIL by syslog specification.
  severity_key RECORD_SEVERITY_KEY
  facility_key RECORD_FACILITY_KEY
  hostname_key ...
  app_name_key ...
  procid_key ...
  msgid_key ...
</match>
```
