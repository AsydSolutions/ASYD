Supported Systems
=================
<br/>

Even though ASYD in theory works with any system supporting SSH, there's some
system-specifics functions, like the install command or the monitoring setup, that will only
work on the officially supported systems.

*Note for developers: if you want to use ASYD with any other system anyway, you can
comment out the line `raise #OS not supported yet` on the initialize() function in models/host.rb. We are not
responsible of strange behaviors this could lead.*

<br/>
Supported Clients:
------------------

You can currently add systems based on:

 * Debian
 * Ubuntu
 * RedHat
 * Fedora
 * CentOS
 * Arch Linux
 * OpenSUSE
 * Solaris/OpenIndiana
 * OpenBSD

*Note: any derivation or distribution based on the listed above should work as well.
If you find any issue on any of the supported systems or systems based on them, please
report back to us at info@asyd-solutions.com*

<br/>
Supported Servers:
------------------

You can install ASYD itself on any Linux/UNIX/POSIX system with Ruby support except for MacOS,
due to a known bug on the forking process.
