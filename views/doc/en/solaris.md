Solaris
=======
<br/>
ASYD supports both Solaris (from version 8 on) and OpenIndiana, but these systems have
some particularities, described below.

<br/>
Package Managers
----------------
<br/>
As Solaris have different package managers or ways of installing packages depending on the
version, ASYD performs some internal checks regarding this topic.

ASYD currently supports the installation of packages using

**1. pkgadd**

The oldest package manager for Solaris, and available on any Solaris/OpenIndiana system.
On Solaris 10 and higher, pkgadd supports URLs so you can install packages directly from
internet by just specifying the URL on both the `install` command on a def file or using the
"Quick Install". For Solaris 9 and below, you need to first download the package to some
directory and install it specifying the full path.

The installation command for this package manager on ASYD performs as
`pkgadd -a /etc/admin -d <packagename> all`, installing all the contents on the package.
The `/etc/admin` file is uploaded during the Monitoring setup to avoid prompts when using pkgadd.

**2. pkg**

This package manager is available on Solaris 11 and OpenIndiana. It works similar to
package managers on Linux, by downloading packages from a software repository. It has
no special requirements.

**3. pkgutil**

Not native to Solaris but from the third party repository [OpenCSW](http://www.opencsw.org).
It works on any version of Solaris/OpenIndiana and brings a lot of common utilities and
software. ASYD does installs OpenCSW on the Solaris/OpenIndiana systems when deploying
the monitoring, however you can disable it by removing or commenting out the line on the
def and def.sudo files for the "monit" deploy.

Works the same as any other package manager, thus not requiring any special options.

<br/>
Installing Software
-------------------
<br/>
By default the `install` command without parameters, or the "Quick Install", will use
`pkg` as package manager, or if this one is unavailable, it will use `pkgadd`.

You can override the default behavior on the `install` command by appending one of the
package managers:

  * pkgadd: `install pkgadd [if condition]: package`
  * pkg: `install pkg [if condition]: package`
  * pkgutil: `install pkgutil [if condition]: package`

Same applies to the `uninstall` command.

