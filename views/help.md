Basics
------

**Adding servers:**

Browse to the "Servers" section for adding servers, you only need to provide a
unique hostname, the server IP and the -root- password.
ASYD will add the ASYD ssh key on the ~/.ssh/authorized_keys file of the target server
for all the future access, so the password won't be stored.

**Adding hostgroups:**

Browse to the "Hostgroups" section and click on "Add group". Then you can just
open the newly created group, and add servers to it.

**Installing packages:**

You can also install single packages on any host or hostgorup in the "Deploys" section,
on the "Quick Install" dialog. You can install multiple packages separated by spaces
(i.e. htop nano vim).

Deploys
-------

Deploys are stored on the "data/deploys/" directory in your ASYD installation.

**Creating a deploy:**

Deploys on ASYD have the following structure:

* A directory named with the name of the deploy (i.e. data/deploys/LAMP/)
* A "def" file with the definition of the packages to be installed,
  configurations, commands to be executed, etc. (i.e. data/deploys/LAMP/def)
* A "configs" directory with the configuration files and folders to be uploaded
  (i.e. data/deploys/LAMP/configs/apache/apache.conf)

The def file structure is as follows:

    install [if <condition>]: package_a package_b package_c
    config file [if <condition>]: file.conf, /destination/file.conf
    config dir [if <condition>]: confdir, /destination/dir
    exec [host][if <condition>]: command
    monitor [if <condition>]: service
    deploy [if <condition>]: another_deploy
    reboot [if <condition>]

**Deploy example:**

`cat data/deploys/LAMP/def`

    install: apache mysql-server php5
    config dir: apache2, /etc/apache2
    config file: php.ini, /www/php.ini
    exec: service apache2 restart
    monitor: apache mysql

`ls data/deploys/LAPM/configs/`

- apache2/
- php.ini


Variables
---------

You can use the following global variables on any configuration file, they will
get automatically replaced with it's value.

    <%ASYD%> - ASYD IP
    <%HOSTNAME%> - Target host name
    <%IP%> - Target host IP
    <%DIST%> - Target host linux distribution
    <%DIST_VER%> - Target host distribution version
    <%ARCH%> - Target host architecture
    <%MONITOR:service%> - Monitors the service 'service'

You can define custom variables on both hosts and hostgroups, if a host has the
same variable name as his hostgroup, it will use the host one, so you can override
variables on selected hosts inside a group

    <%VAR:varname%> - Replaces the value assigned to "varname"

All this variables can be used on any configuration file inside the "configs"
directory on a deploy, inside the "data/monitors/" directory, or as conditionals
for "def" files on a deploy.

Conditionals
------------

Valid conditions are == (equal), != (different), >= (greater or equal) and <= (lower or equal).

Example condition:

`install if <%DIST%> == debian and <%DIST_VER%> == 6 or <%DIST%> == centos and <%DIST_ver%> >= 5: package`

Monitors
--------

Monitors are standard [monit](http://mmonit.com/monit/) configurations, stored under the "data/monitors/modules/" directory.

You can use any ASYD variable or custom variable on them as for any other configuration files.

You can also modify the "data/monitors/monitrc" for tunning the monitrc file configuration
