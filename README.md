# Primero modificar 



Starting up....
$ oc cluster up --public-hostname '10.200.193.235'



Documentation: https://docs.openshift.com/container-platform/3.6/dev_guide/managing_images.html#using-image-pull-secrets




We need either a ~/.docker/config.json where credentials aren’t store in OSX keychain but in the older format (Base 64) or use the second option below:

$ oc secrets new rhmap-dockerio .dockerconfigjson=/Users/cvicensa/Projects/openshift/fh-cup/RHMAP/misanche-docker.json
$ oc secrets new-dockercfg <pull_secret_name> \
    --docker-server=<registry_server> --docker-username=<user_name> \
    --docker-password=<password> --docker-email=<email>
 

Now let’s link the secret to the default service account for pulling images

$ oc secrets link default rhmap-dockerio --for=pull


Using oc-cluster-wrapper
Alias to use always the same IP
$ sudo ifconfig en0 alias 192.168.50.100 255.255.255.0

Change dir to oc-cluster-wrapper (or put it in your PATH)
$ cd /Users/cvicensa/Projects/openshift/oc-up-rhmap/oc-cluster-wrapper

Start up your cluster...
$ ./oc-cluster up rhmap4.4  --public-hostname=192.168.50.100



Local CA

Generate CA certs

$ docker run --rm -v $(pwd)/ca:/etc/cfssl dhiltgen/cfssl genkey -initca ca.json | \
docker run --rm -i -v $(pwd)/ca:/etc/cfssl --entrypoint cfssljson dhiltgen/cfssl -bare ca

Transform from PEM to DER
$ openssl x509 -in ca.pem -text -noout -extensions v3_ca > ca.cer

Run the server

$ docker run -d -v $(pwd)/ca:/etc/cfssl --name cfssl dhiltgen/cfssl serve -address=0.0.0.0 -config=config.json

Generate host cert

$ mkdir proxy-certs
$ cd proxy-certs
cat << EOF > mycert.json
{
    "hosts": [
        "core.apps.192.168.1.136.nip.io"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "CN": "core.apps.192.168.1.136.nip.io"
}
EOF

$ docker run --rm --link=cfssl -v $(pwd):/etc/cfssl --entrypoint=/bin/sh dhiltgen/cfssl -c \
    'cfssl gencert -remote $CFSSL_PORT_8888_TCP_ADDR -profile=server mycert.json' | \
    docker run --rm -i -v $(pwd):/etc/cfssl --entrypoint cfssljson dhiltgen/cfssl -bare mycert

Let’s Encrypt
Sólo si se tiene una IP pública...
Generate certs

docker run \
  -v $(pwd)/nginx-ssl:/etc/letsencrypt \
  -e http_proxy=$http_proxy \
  -e domains="192.168.1.136.nip.io,core.192.168.1.136.nip.io, cloud.192.168.1.136.nip.io,weyland.org" \
  -e email="carlos.vicens.alonso@gmail.com" \
  -p 7777:80 \
  -p 7443:443 \
  --rm pierreprinetti/certbot:latest

# Intro
This documents is a guide to install RHMAP on Openshift using ‘oc cluster up’.

**Caveat:** There are some steps that are optional and others are in this document because of a bad behaviour that could be fixed in the future.
Using oc-cluster-wrapper to manage configurations
We’re going to use [oc-cluster-wrapper](https://github.com/openshift-evangelists/oc-cluster-wrapper) as a convenient way to provide persistence to ‘oc cluster up’ and also to manage different cluster configurations in the same machine.

**Note:** persistence itself is a matter of setting some parameters correctly as explained [here](https://stackoverflow.com/questions/41539780/making-openshift-origin-docker-containers-persistent-after-reboot)

But before we start up our cluster we need to create a network interface alias in an interface different to loopback for two reasons:
Apparently RHMAP installation fails if IP is like 127.x.x.x
You want to be able to start your cluster in the same IP always

Next we’ll download ‘oc-cluster-wrapper’ (or clone its repository) and create a cluster.

## Create an IP alias
Go [here](http://osxdaily.com/2009/08/05/how-to-create-an-ip-alias-in-mac-os-x-using-ifconfig/) for a longer explanation, next example creates an IP alias for interface **en0** and IP **192.168.50.100**.

```$ sudo ifconfig en0 alias 192.168.50.100 255.255.255.0```

## Clone or download oc-cluster-wrapper
Go to [oc-cluster-wrapper](https://github.com/openshift-evangelists/oc-cluster-wrapper) and follow instructions.

## Create your OCP cluster to install RHMAP on top
Change dir to oc-cluster-wrapper (or put it in your PATH) and start up your cluster… in this case name is **rhmap4.4** and IP is **192.168.50.100**.

```
$ ./oc-cluster up rhmap4.4  --public-hostname=192.168.50.100
# Using client for origin v3.6.0
[INFO] Created self signed certs. You can avoid self signed certificates warnings by trusting this certificate: /Users/cvicensa/.oc/certs/master.server.crt
[INFO] Running a new cluster
[INFO] Shared certificates copied into the cluster
oc cluster up --version v3.6.0 --image openshift/origin --public-hostname 192.168.50.100 --routing-suffix apps.192.168.50.100.nip.io --host-data-dir /Users/cvicensa/.oc/profiles/rhmap4.4/data --host-config-dir /Users/cvicensa/.oc/profiles/rhmap4.4/config --host-pv-dir /Users/cvicensa/.oc/profiles/rhmap4.4/pv --use-existing-config -e TZ=CEST
Starting OpenShift using openshift/origin:v3.6.0 ...
OpenShift server started.

The server is accessible via web console at:
    https://192.168.50.100:8443

You are logged in as:
    User:     developer
    Password: <any value>

To login as administrator:
    oc login -u system:admin

-- Any user is sudoer. They can execute commands with '--as=system:admin'
-- 10 Persistent Volumes are available for use
-- User admin has been set as cluster administrator
Switched to context "rhmap4.4".
-- Adding an oc-profile=rhmap4.4 label to every generated image so they can be later removed
[INFO] Cluster created succesfully
Restarting openshift. Done
cvicensa-mbp:oc-cluster-wrapper cvicensa$ ./oc-cluster list
# Using client for origin v3.6.0
Profiles:
- rhmap4.4
```

So far we have created and stored an OCP configuration for 'oc cluster up' with a given name we can use to start/stop our cluster at any time.

If you need to see the console URL afterwards, run the following command.

```
$ ./oc-cluster console
# Using client for origin v3.6.0
https://192.168.50.100:8443/console
```

# Installing RHMAP with Ansible playbooks

We're going to install RHMAP using ansible playbooks in [github/fheng/rhmap-ansible](https://github.com/fheng/rhmap-ansible), in fact we're going to use ./rhmap-ansible/playbooks/poc.yml. In order to do so we'll need to select/create an ansible inventory and override the default paths to find the templates to install RHMAP. These templates can by found by default at /opt/rhmap/{{ rhmap_version }}/templates/core for '**core**' and at /opt/rhmap/{{ rhmap_version }}/templates/mbaas for '**mbaas**', by default I mean if you follow the steps to install RHMAP using yum (``yum install rhmap-fh-openshift-templates``) [here](https://access.redhat.com/documentation/en-us/red_hat_mobile_application_platform/4.5/html/installing_rhmap/preparing-infrastructure-for-installation#install-openshift-templates).

Let's clone (remember you need access to fheng git repo) the rhmap-ansible repo.

```
$ git clone https://github.com/fheng/rhmap-ansible
```

Before we run our playbook we need to setup the ansible inventory. To do so, we're going to use ``./rhmap-ansible/inventory-templates/fh-cup-example``, edit the file with your favorite editor and change the variables '**login_url**' and '**master_url**' to point to your OCP cluster. If you have created the IP alias these variables should point to https://<IP_ALIAS>:8443 as in the following excerpt.

```
...
login_url="https://192.168.50.100:8443"
...
master_url="https://192.168.50.100:8443"
...
```

Additionally you can change the values of the variables that point to the build farm in ``./roles/deploy-core/defaults/main.yml`` as in the following excerpt. In our case both variables should point to ``https://farm.eu.redhatmobile.com``. It is possible to change this later. 

```yaml
frontend:
  ...
  git_external_protocol: "https"
  builder_android_service_host: "https://androidbuild.feedhenry.com"
  builder_ios_service_host: "https://iosbuild.feedhenry.com"

```

# Create a secret to hold docker hub credentials and link it to the default account for pulling images

First we need to create a secret (**rhmap-dockerio** in our example) with our docker hub credentials (you have to be added to organization 'rhmap' in order to be able to pull all the needed images). Next example shows how to create the secret.

```
$ oc secrets new-dockercfg rhmap-dockerio  --docker-server=https://index.docker.io/v1/ --docker-username=<DOCKER_USER> --docker-password=<DOCKER_PASS> --docker-email=<DOCKER_EMAIL>

```

Now let's link the secret '**rhmap-dockerio**' to the default account for pulling images.

```
oc secrets link default rhmap-dockerio --for=pull
```

# Execute the poc.yml ansible playbook

```
$ cd ./rhmap-ansible
$ ansible-playbook -i inventory-templates/fh-cup-example playbooks/poc.yml -e "core_templates_dir=/Users/cvicensa/Projects/openshift/oc-up-rhmap/fh-core-openshift-templates/generated" -e "mbaas_templates_dir=/Users/cvicensa/Projects/openshift/oc-up-rhmap/fh-openshift-templates" -e "mbaas_project_name=mbaas" -e "core_project_name=core" -e "strict_mode=false" --tags deploycvicensa-mbp:oc-up-rhmap cvicensa
```

The installation can get stuck at 'ups' application deployment in project 'core', if that is the case Ctrl+C and re run the script.








