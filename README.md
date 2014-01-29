# fluent-plugin-mobile-carrier

## MobileCarrierOutput

'fluent-plugin-mobile-carrier' is a Fluentd plugin to judge mobile carriers from IP address.
'fluent-plugin-mobile-carrier' needs external config yaml file, which includes Carrier-IPAddress settings.


## Configuration

To add mobile_carrier result into matched messages:

    <match input.**>
      type mobile_carrier
      key_name ip_address
      config_yaml config.yaml
      remove_prefix input
      add_prefix merged
    </match>

## Copyright

* Copyright (c) HARUYAMA Seigo
* License
  * Apache License, Version 2.0
