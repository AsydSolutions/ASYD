Basics
======
<br/>

Almost everything in ASYD works using the web interface. It allows you to manage
all the systems, hostgroups, users, teams, monitor your servers and manage and launch
deploys.

The monitoring is handled by [monit](http://mmonit.com/monit/) on the remote hosts,
which communicates with the ASYD server.

<br/>
Adding Hosts and Hostgroups:
----------------------------
<br/>
Once you are logged in to ASYD, go to the "Server overview" section. There you will
see the existing hosts and hostgroups, the hosts belonging to a hostgroup and the system
status for your servers.

On the overview you can open the detail of the hosts or hostgroups, perform a reboot of a
remote system, remove existing hosts and hostgroups or add new.

For adding a new server, click on the "Add host" button and a prompt will appear.
There you need to provide a unique hostname, the server IP, the user for that host,
the ssh port (if you configured a non-standard port), and the password for that user.
ASYD then will add the ASYD ssh key to the ~/.ssh/authorized_keys file of the target host
for all the future access, thus the provided password won't be stored at all. Alternatively,
you can leave the password field empty. Then ASYD will try to auth against the host using the
SSH key created or provided at the setup.

Please note that if you are using a non-root user (like in the case of ubuntu or similar),
you need to be sure that the user has admin privileges, the command "sudo" is installed,
and the user won't be prompted for a sudo password, as ASYD deploying system is non-interactive.
This can be achieved by adding `%sudo   ALL=(ALL:ALL) NOPASSWD:ALL` on the `/etc/sudoers` file.

After the new host it's added, it will start the monitoring deploy on the background. At this
time the server will appear as "not monitored". When the monitoring setup has completed,
opening the host detail will display you all the system information, the status reported by
monit. It will also allow you to create new custom variables for the host.

For adding a new hostgroup, click on the "Add group" button, and a prompt will appear. There
you need to provide a unique name for the new hostgroup.

After the new hostgroup it's created, you can open the detail of the group and add servers
or custom variables to it. A single host can be included on several groups.

<br/>
Quick Install:
--------------
<br/>

ASYD offers the possibility of installing single packages into a host or hostgroup. For
doing this, go to the "Deploys" section and use the "Quick Install" dialog box. You can
also install multiple packages separated by spaces (i.e. htop nano vim).

The installation routine is handled by ASYD which will check the kind of system and the
package manager to use, so this option can be used to install packages on any kind of
system. Please keep in mind packages are not always named the same on all the systems,
so unless you are sure that the package name is the same across distributions, you should
not use this feature on groups containing highly different systems.

Please also read the [Solaris](solaris.md) section for more detailed information on how the quick install
behaves on Solaris systems.

<br/>
ASYD data structure:
-------------------
<br/>

  * `asyd.rb - config.ru`: base files for ASYD to work, `asyd.rb` contains the basic
  initialization routines and `config.ru` allows Phusion Passenger to start and manage
  the application.
  * `installer/`: contains the predefined monitor files and the monitoring deploy
  for launching monit on the added hosts. This folder gets deleted after the setup is complete.
  * `models/`: contains all the ASYD core, all the functions for it to work.
  * `routes/`: contains the routes and actions to be performed depending on the request.
  * `views/`: contains all the views (web pages) to be displayed on the web interface.
  * `static/lib/`: contains all the javascript, css and images for the views.
  * `data/`: stores ASYD data
    * `data/db/`: several SQLite DB files to store hosts, hostgroups, users, teams,
    tasks, notifications, monitoring notifications and system status.
    * `data/deploys/`: where the deploys are stored (detailed information on the
    [Deploys](deploys.md) section of the documentantion).
    * `data/monitors/`: monit definition files for monitoring services.
