Deploys
=======
<br/>
A "deploy" is group of executable definitions and configurations which allows you to
automatically install or uninstall software, upload and parse configurations, execute
commands on the target system or a third (defined) system, monitor services and, in general,
set up your infrastructure and make it ready for production with a single click.

The deploys can be found or uploaded to the "data/deploys/" directory in your ASYD installation.

<br/>
Deploy structure:
-----------------
<br/>

* A directory named with the name of the deploy (i.e. `data/deploys/LAMP/`). This name will
be displayed on the ASYD web interface on the "Deploys" sections.
* A "def" file (i.e. `data/deploys/LAMP/def`) with the definition of what the deploy will do -
packages to install, commands to execute, configurations to upload, conditions, etc.
* Optionally, a "def.sudo" file (i.e. `data/deploys/LAMP/def.sudo`) in case we want to
execute this file instead of the standard "def" when using a non-root user (see note below).
* Optionally, an "undeploy" file (i.e. `data/deploys/LAMP/undeploy`) with the steps required to
revert (undeploy) a Deploy.
* Optionally, an "undeploy.sudo" file (i.e. `data/deploys/LAMP/undeploy.sudo`) being the "undeploy"
equivalent of "def.sudo".
* A "configs" directory with the configuration files and folders to be uploaded
(i.e. `data/deploys/LAMP/configs/apache/apache.conf`).

**Note about "def.sudo":** this definition file will be executed instead of the normal "def" file only in case
the user executing on the remote machine is not "root" and this file is present. This is especially useful on
Ubuntu machines which don't use the root user. For the machines where the user is "root", the standard
"def" file will be executed regardless the existence of "def.sudo". If this file is not present,
the standard "def" file will be executed also for non-root users. Same applies to "undeploy.sudo".

<br/>
The "def" file:
------------------
<br/>
Both the "def" and "def.sudo" files, used for defining a deploy, accept the following
commands and parameters. The same rules applies for the "undeploy" and "undeploy.sudo" files.

*Please note the colon - : - after the conditionals and before
the arguments, as it's required for the deploy to work.*

**0. comments**

Any line starting with a hash (#) is interpreted as a comment and won't be executed.
There's an special kind of comment, the alert, which displays an alert message before launching the deploy. This
is useful in case your deploy require some custom variables or you want to warn the user to check
something before executing a deploy. Please note that the alerts only work on "def" files and not in "def.sudo".
The alerts are done by starting a line with `# alert:`

*Syntax:* `# Normal comment`

*Syntax:* `# Alert: Message to display before confirming the execution of a deploy`

**1. install / uninstall**

The install command can be used to define a (space separated) list of packages to be installed
on the target system. Internally, ASYD will check the kind of system on which is going to install
the packages and will use the appropriate package manager for it. Optionally you can define
conditionals - please read the [Conditionals](conditionals.md) section of the documentation for usage information.
On Solaris systems it also accept an extra argument for defining the package manager. Please check the
[Solaris](solaris.md) section of the documentation for more detailed information.

*Syntax:* `install [if <condition>]: package_a package_b package_c`

The uninstall command performs like the install command, but for removing software packages.
It also accepts conditionals optionally and package manager in the case of [Solaris](solaris.md).

*Syntax:* `uninstall [if <condition>]: package_a package_b package_c`

**2. config file**

This command allows you to upload a configuration stored in the "configs" directory (first parameter)
to the path defined for the target host (second parameter). The name of the local file must be
written as is named inside the "configs" directory of the deploy, but you can use any name
on the target as it will get renamed when uploaded. Optionally it also accepts conditionals
and a "noparse" argument in case you don't want the configuration file to be parsed before uploading
but to be uploaded as-is. Please also read the [Configurations](configurations.md) section of the documentation.

*Syntax:* `[noparse] config file [if <condition>]: file.conf, /destination/file.conf`

**3. config dir**

Behaves the same way as the "config file" command, but inspects recursively all the files and
subfolders inside the defined directory, parsing each one of the configuration files in there.
Like for "config file", it also accepts the optional conditionals and the "noparse" parameter
(see "config file" above).

*Syntax:* `[noparse] config dir [if <condition>]: confdir, /destination/dir`

**4. exec**

This command simply executes any user defined (bash/sh) command, thus is the most versatile
command on ASYD. It accepts optionally conditionals and also a host parameter, on which you can
specify any other host on which the command should be executed, instead of the target of the
deploy (for example if you wish to update a database or perform any action on a defined host
every time a new system is deployed). The exec command also accepts any variable on the defined
command, so you can include there passwords, variable parameters, system information, etc. as
parameters for any command.

*Syntax:* `exec [host] [if <condition>]: command`

**5. http**

This command allows you to perform an HTTP GET or POST request from a deploy. This call is performed
by the ASYD server instead of the target host. It is particulary useful for interacting with an API,
as you can also use "http" from the "var" command to store it's return (see next point).

*Syntax:* `http get [if <condition>]: url`

*Syntax:* `http post [if <condition>]: url[, key1=val1, key2=val2, ...]`

**6. var**

This command allows you to set a host variable from a "def" or "undeploy" file, which can be called
later as a normal variable (<%VAR:varname%> - see [Variables](variables.md)). The variable can be
set with the output of an "exec" command - make sure the command produces an output - or "http" command.
If a variable with the same name exists, it will be overwritten to the new value.

*Syntax:* `var <varname> = exec [host] [if <condition>]: command`

*Syntax:* `var <varname> = http <get|post> [if <condition>]: url[, key1=val1, key2=val2, ...]`

**7. monitor / unmonitor**

This command allows you to monitor (or stop monitoring if "unmonitor" is used) a service. The service parameter must have the same name
as the "monitor" file inside the `data/monitors` directory, which must exist. You can
also specify several services separated by spaces. It also accepts optionally conditionals.

*Syntax:* `monitor [if <condition>]: service`

*Syntax:* `unmonitor [if <condition>]: service`

**8. deploy / undeploy**

With this command you can also launch other deploys from a deploy, even allowing you to create
a meta-deploy defining the deploys that should be launched depending on conditionals. The
named deploy must exist. This command also accepts conditionals optionally.

*Syntax:* `deploy [if <condition>]: another_deploy`

The "undeploy" command behaves the same way but using the `undeploy` file instead of
the normal `def` file.

*Syntax:* `undeploy [if <condition>]: another_deploy`

**9. reboot**

It simply reboots a system. This command doesn't requires the colon - : - and the only
optional parameter allowed is a conditional. **Please note** that this command should always
be used at the end of a deploy, else, the ASYD server will lose communication with the
target host and the following commands won't be executed.

*Syntax:* `reboot [if <condition>]`
