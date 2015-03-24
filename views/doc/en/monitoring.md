Monitoring
==========
<br/>
The monitoring of servers and services in ASYD is handled by [monit](http://mmonit.com/monit/).
The ASYD server check against the local monit installation on the remote host for
any changes on the status of the server itself or any service being monitored.

<br/>
Set Up
------
<br/>
The monitoring is automatically set up on every host added to ASYD using a "deploy"
which installs and configures **monit** on any of the supported systems.

This "deploy" can be found under `data/deploys/monit/` after the initial setup is done.
You can also modify this deploy according to your needs. Please read the [Deploys](deploys.md)
section on the documentation.

<br/>
Monitors
--------
<br/>
Monitors are standard monit configuration files defined for single services.

This files are stored under `data/monitors/` and they accept conditionals and variables
as for any other configuration file (see [Configurations](configurations.md) on the documentation), allowing
you to write a single monitor file for any kind of host.

The file name for the monitor file must have the same name as the service being monitored
(i.e. for monitoring nginx you should place the monitor file as `data/monitors/nginx`).

You can monitor services

1. Using the `monitor` command on a "def" file.
2. Placing on any configuration file the `<%MONITOR:service%>` tag where service is the name
of the service as written on the monitor filename.
