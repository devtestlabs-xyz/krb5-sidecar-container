# KRB5 Sidecar Container
![](https://github.com/devtestlabs-xyz/krb5-sidecar-container/workflows/Build%20and%20Publish%20Docker/badge.svg)

This project provides a lightweight Docker image purpose built as a MIT KRB5 sidecar. This container manages all aspects of the Kerberos authentication workflow and provides shared memory access to those Kerberos runtime assets required for the sidecar client to connect to an external service such as a MSSQL server configured to only allow intergrated authentication. The only requirement of the containerized client application/service is to install the `krb5`, `krb5-user`, or `krb5-workstation` package and reference the sidecar container in the Docker `--ipc` cli option, a Docker Compose file, an Openshift configuration file, or K8s configuration file. This solutions works on most platforms!

This sidecar is particularly useful in hybrid Linux/Windows environments in which Active Directory is used for authentication and authorization. The benefits are:
* a common implementation of Kerberos authentication management
* allows containerized dotNET Core applications running on Linux hosts to authenticate with MSSQL configured for integrated authentication (Kerberos authentication via Active Directory)

The inspiration for this solution came from the following article and implementation:

* https://blog.openshift.com/kerberos-sidecar-container/
* https://github.com/edseymour/kinit-sidecar

The published OCI container image is based on the [official Alpine Linux Docker image](https://hub.docker.com/_/alpine).

*IMPORTANT: This solution relies on universal linux shared memory (`/dev/shm`) and [Docker container IPC namespaces](https://docs.docker.com/engine/reference/run/#ipc-settings---ipc) to share KRB5 assets and tickets between containers.*

# Getting Started
## Get the image from DockerHub
The OCI image is currently published to https://hub.docker.com/u/devtestlabs/krb5-sidecar-container.

```
docker pull devtestlabs/krb5-sidecar
```

## Run a container
To run a useful sidecar container you must provide the required environment variable values and bind mounts. You may run this container in interactive, attached mode for evaluation/testing purposes. You should run the container in detached mode for production use.

### Environment Variables
Environment variables transmitted to the Docker container instance may be specified using the `-e` cli option or managed in a file that is referenced in the `--env-file` cli option or a combination of both methods. Managing environment variables in a file and using the `--env-file` cli option is probably the most useful for this case.

Here's the contents of an example environment variable file named `.env.test` contained in the `conf/` path of this project. The format is one environment variable definition per line; VAR_NAME=VAR_VALUE.

```
# conf/.env.test
# Example file used to transmit environment variables to `docker run`
KINIT_WAIT_INTERVAL_IN_SECONDS=3600
KINIT_OPTIONS=-k bob.wills@EXAMPLE.COM
# KRB5 Credentials Cache path and name (file type)
KRB5CCNAME=/dev/shm/ccache
KRB5_KTNAME=/krb5/common/krb5.keytab
KRB5_CLIENT_KTNAME=/krb5/common/client.keytab
KRB5_CONFIG=/etc/krb5.conf
```

* `KINIT_WAIT_INTERVAL_IN_SECONDS`: *Optional*. Default is `3600` seconds. Sets the wait time between `kinit` execution. `kinit` refreshes the Kerberos token/ticket.

* `KINIT_OPTIONS`: *Mandatory*. `-k someuser@EXAMPLE.COM` tells `kinit` to request a Kerberos token for the `someuser@EXAMPLE.COM` using the associated Kerberos keytab file specified in configuration. In this way, no credentials are passed to the target authentication/authorization service(s).

* `KRB5CCNAME`: *Optional*. Default is `/dev/shm/ccache`. This tells `KRB5` where to store the credentials cache. `/dev/shm/ccache` is the universal ramdisk (shared memory) for Linux. All KRB5 runtime assets that must be shared with the sidecar client container are put in this shared memory location.

* `KRB5_KTNAME`: *Optional*. Default is `/krb5/common/krb5.keytab`. This tells `KRB5` where to look for the default keytab file.

* `KRB5_CLIENT_KTNAME`: *Optional*. Default is `/krb5/common/client.keytab`. This tells `KRB5` where to look for the default client keytab file.

* `KRB5_CONFIG`: *Optional*. Default is `/etc/krb5.conf`. This is where `KRB5` looks for the default configuration file.

### Bind mounts
The `docker run` commands below provide examples of the required bind mounts.

One volume `VOLUME ["/krb5"]`, is configured in this docker image. You'll need to provide the host-side of the bind mount. You can specify the bind mount using `-v` or `--volume` or the more flexible `--mount` switch to bind mount the `krb5` destination path to the host (source) path. See https://docs.docker.com/storage/bind-mounts/ for more information about docker bind mounts.

The `krb5` volume is used to manage the required MIT Kerberos assets such as the default configuration file `krb5.conf` and supplementary configuration files. Within the `krb5` path are the following subpaths:

* `client`: Contains the `krb5.conf` default configuration that should work for any sidecar client. Ultimately, this file is put in shared memory so that `KRB5` in the client container is configured to use the other required runtime KRB5 assets that reside in the sidecar shared memory.

* `sidecar`: Contains the `krb5.conf` default configuration that should work for any sidecar. This file is only used by the sidecar container.

* `common`: This is where you put the Kerberos keytab file. You can use the `devops/krb5-keytab-generator` container to generate a valid keytab that will be useful for most Windows, Active Directory, and MSSQL Kerberos-based authentication use cases.

* `common/krb5.conf.d`: This is where all supplementary configuration files should be put. These configurations will be used by the sidecar and client containers.

Here's an example of a supplementary configuration file that describes the default realm and realm specifications for the EXAMPLE.COM realm:

```
# krb5/krb5.conf.d/krb5-EXAMPLE_COM.conf
# KRB5 supplementary and override configuration for EXAMPLE_COM
[libdefaults]
default_realm = EXAMPLE_COM
ticket_lifetime = 6h

[realms]
        EXAMPLE_COM = {
        kdc = dc1.example.com
        admin_server = dc1.example.com
        }

[domain_realm]
        example.com = EXAMPLE.COM
```

### KRB5 assets
All required KRB5 assets are described in the "Bind Mounts" section above.

### Run a container interactively (attached)

```
docker run \
-it \
--rm \
--dns=10.1.2.132 \
--dns=10.1.2.133 \
--ipc="shareable" \
--name krb5-sidecar \
--mount type=bind,source="$(pwd)"/krb5,target=/krb5 \
--env-file conf/.env.test \
devtestlabs/krb5-sidecar:latest 
```

### Run a detached container 
```
docker run \
-d \
--rm \
--dns=10.0.1.200 \
--dns=10.1.2.201 \
--ipc="shareable" \
--name krb5-sidecar \
--mount type=bind,source="$(pwd)"/krb5,target=/krb5 \
--env-file conf/.env.test \
devtestlabs/krb5-sidecar:latest 
```

## Evaluate the Kerberos Sidecar container and Client container
If you want to test the sidecar a simple client container is provided in this project. The client Docker image is published on Dockerhub and can be pulled or you can build it locally.

### Pull the test client image
```
docker pull devtestlabs/krb5-test-client
```

### Build a test client image
```
cd test/
docker build -t devtestlabs/krb5-test-client .
```

### Generate keytab file
*TODO: publish keytab generator OCI image*
You can use the `devtestlabs/krb5-keytab-generator` container to generate a valid keytab that will be useful for most Windows, Active Directory, and MSSQL Kerberos-based authentication use cases.

Read:

* [Windows Users - How to generate a Kerberos keytab that is compatible with Active Directory](https://social.technet.microsoft.com/wiki/contents/articles/36470.active-directory-using-kerberos-keytabs-to-integrate-non-windows-systems.aspx)

* [Windows and Linux Users - How to generate a Kerberos keytab that is compatible with Active Directory](http://www.itadmintools.com/2011/07/creating-kerberos-keytab-files.html)


### Put other KRB5 assets in krb5/ path

Copy the contents below into a file named `krb5-YOUR_FQDN.conf`. Put this file in the `krb5/common/krb5.conf.d` project path.

*example krb5 supplemental/override configuration file*
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

*NOTE: Replace `EXAMPLE.COM` and `example.com` with your domain name. Mind the capitalization! Realm specifications MUST be ALL CAPS!*

Next, fetch your keytab file you generated with the KRB5 Keytab Generator. Put this keytab file in the `krb5/common` project path. Rename the file `krb5.keytab`. *NOTE: All these paths and names are configurable but for ease of use follow the instructions.*

### Construct .env file
Create the `.env.test` file with the following contents. 

*NOTE: REPLACE `{{ PRINCIPAL_NAME }}` with the Active Directory username you created the keytab for. Replace `{{ REALM }}` with your Kerberos Realm name.*

*generic .env file contents*
```
KINIT_WAIT_INTERVAL_IN_SECONDS=3600
KINIT_OPTIONS=-k {{ PRINCIPAL_NAME }}@{{ REALM }}
# KRB5 Credentials Cache path and name (file type)
KRB5CCNAME=/dev/shm/ccache
KRB5_KTNAME=/krb5/common/krb5.keytab
KRB5_CLIENT_KTNAME=/krb5/common/client.keytab
KRB5_CONFIG=/etc/krb5.conf
```
*concrete example .env file contents*
```
KINIT_WAIT_INTERVAL_IN_SECONDS=3600
KINIT_OPTIONS=-k bob.wills@EXAMPLE.COM
# KRB5 Credentials Cache path and name (file type)
KRB5CCNAME=/dev/shm/ccache
KRB5_KTNAME=/krb5/common/krb5.keytab
KRB5_CLIENT_KTNAME=/krb5/common/client.keytab
KRB5_CONFIG=/etc/krb5.conf
```

### Run a sidecar container interactively (attached)
If you're in `test` path, `cd ..`

Start `terminal`, ensure the docker daemon is running and execute:

```
docker run \
-it \
--rm \
--dns=10.0.1.200 \
--dns=10.0.2.201 \
--ipc="shareable" \
--name krb5-sidecar-test-123 \
--mount type=bind,source="$(pwd)"/krb5,target=/krb5 \
--env-file conf/.env.test \
devtestlabs/krb5-sidecar:latest 
```
*IMPORTANT: The `--name` value must be unique. If you have any other sidecar containers running ensure the name value is unique!*

### Start client container
Open a new terminal session and execute:

```
docker run \
-it \
--rm \
--dns=10.1.2.132 \
--dns=10.1.2.133 \
--ipc "container:krb5-sidecar-test-123" \
--name krb5-sidecar-client \
devtestlabs/krb5-test-client:latest 
```

*IMPORTANT: `The --name value must be unique. If you have any other client containers running ensure the name value is unique!*
*IMPORTANT: `The --ipc value must match the name given to the sidecar container you wish to share memory with.*

Watch the output in the session. 


# Build the image locally
```
docker build -t krb5-sidecar .
```

# External References

* https://blog.openshift.com/kerberos-sidecar-container/

* https://github.com/edseymour/kinit-sidecar

* https://pkgs.alpinelinux.org/contents?branch=edge&name=krb5&arch=x86&repo=main

* https://dzone.com/articles/docker-in-action-the-shared-memory-namespace

* https://docs.docker.com/engine/reference/run/#ipc-settings---ipc

* https://web.mit.edu/kerberos/krb5-1.5/krb5-1.5/doc/krb5-install/The-Keytab-File.html

* https://web.mit.edu/kerberos/krb5-1.12/doc/basic/ccache_def.html

* https://web.mit.edu/kerberos/krb5-1.12/doc/basic/keytab_def.html#keytab-definition

* https://web.mit.edu/kerberos/krb5-1.12/doc/admin/env_variables.html

* https://web.mit.edu/kerberos/krb5-1.12/doc/mitK5defaults.html#mitk5defaults
