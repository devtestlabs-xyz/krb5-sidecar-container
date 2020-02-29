# krb5/common/krb5.conf.d
This path is used to store supplemental/override KRB5 configuration file(s).

Here's an example of a configuration file specifying realm configurations.

```
# KRB5 supplementary and override configuration for EXAMPLE.COM
[libdefaults]
default_realm = EXAMPLE.COM
ticket_lifetime = 6h

[realms]
        EXAMPLE.COM = {
        kdc = dc1.example.com
        admin_server = dc1.example.com
        }

[domain_realm]
        example.com = EXAMPLE.COM
```

# External References

* https://web.mit.edu/kerberos/krb5-latest/doc/admin/conf_files/krb5_conf.html

* https://insights-core.readthedocs.io/en/latest/shared_parsers_catalog/krb5.html