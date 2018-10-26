# olssite
=========
One click installation of Open LiteSpeed, your Site and SSL.


Description
--------

olssite is a one-click installation script for OpenLiteSpeed. Using this script,
you can quickly and easily install OpenLiteSpeed with some modified config settings. We
also provide a **-s** parameter that will install your site at the same time. 


Running olssite
--------

olssite can be run in the following way:
*./olssite.sh [options] [options] …*

When run with no options, olssite will install OpenLiteSpeed with mostly default
settings and values.

####Possible Options:
* **--adminpassword(-a) [PASSWORD]:** To set set the WebAdmin password for OpenLiteSpeed instead of a random one.
  * If you omit **[PASSWORD]**, olssite will prompt you to provide this password during installation.
* **--email(-e) EMAIL:** to set the administrator email.
* **--lsphp VERSION:** to set LSPHP version, such as 56. We currently support versions 54, 55, 56, and 70.
* **--site(-s) SITEDOMAIN:** To install and setup your site with your chosen domain.
* **--sitepath SITEPATH:** to specify a location for the new site installation or use an existing site installation.
* **--listenport LISTENPORT:** to set the HTTP server listener port, default is 80.
* **--ssllistenport LISTENPORT:** to set the HTTPS server listener port, default is 443.
* **--uninstall:** to uninstall OpenLiteSpeed and remove the installation directory.
* **--purgeall:** to uninstall OpenLiteSpeed, remove the installation directory, and purge all data in MySQL.
* **--version(-v):** to display version information.
* **--help(-h):** to display usage.

===========================================================================================================================
