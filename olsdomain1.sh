#!/bin/bash

FORCEYES=0
ALLERRORS=0

#Site settings
INSTALLSITE=0
SITEPATH=
DOMAIN=*
EMAIL=

#Webserver settings
SERVER_ROOT=/usr/local/lsws
PUBLIC_HTML=/usr/local/lsws/www/
VIRTHOST=$(ps -ef | awk '{for (I=1;I<=NF;I++) if ($I == "virtualhost") {printf echo "," $(I+1)};}' /usr/local/lsws/conf/httpd_config.conf)

fn_install_site() {
    if [ ! -e "$SITEPATH" ] ; then 
            mkdir -p $SITEPATH
	    wget -P $SITEPATH https://github.com/olsscripts/olssite/raw/master/sitefiles.tar.gz
	    cd $SITEPATH
	    tar -xzf sitefiles.tar.gz
	    rm sitefiles.tar.gz
	    mv $SITEPATH/logs $PUBLIC_HTML/$DOMAIN
	    chown -R nobody:nobody $PUBLIC_HTML/$DOMAIN
	    echoG "Domain Installed"
	   
    else
        echoY "$SITEPATH already exists."
    fi
}

fn_install_ssl() {
        #SSL INSTALL#
        systemctl stop lsws
        /usr/bin/certbot-auto certonly --standalone -n --preferred-challenges http --agree-tos --expand --email $EMAIL -d $DOMAIN$VIRTHOST
        systemctl start lsws
		
}

fn_restart_ols() {
	echo
	echo "Domain Installed"
	echo "Restarting OpenLiteSpeed Webserver"
	$SERVER_ROOT/bin/lswsctrl restart
	echo
}

fn_test_domain() {
	echo
        echo "Testing ..."
   	fn_test_site
}

fn_test_webpage() {
	local URL=$1
        local KEYWORD=$2
        local PAGENAME=$3

        rm -rf tmp.tmp
        wget --no-check-certificate -O tmp.tmp  $URL >/dev/null 2>&1
        grep "$KEYWORD" tmp.tmp  >/dev/null 2>&1
    
        if [ $? != 0 ] ; then
        echo "Error: $PAGENAME Failed."
    else
        echoG "OK: $PAGENAME Passed."
	echo
	echo "Congratulations!"
        echo "Your site is now live at https://$SITEDOMAIN"
    fi
    rm tmp.tmp
}

fn_test_site() {
	fn_test_webpage http://$DOMAIN/ "Congratulation" "Site test"  
}

fn_config_httpd() {
    if [ -e "$SERVER_ROOT/conf/httpd_config.conf" ] ; then
        cat $SERVER_ROOT/conf/httpd_config.conf | grep "virtualhost $DOMAIN" >/dev/null
        if [ $? != 0 ] ; then
	    sed -i "/listener\b/a \ \ map                     $DOMAIN $DOMAIN" -i.bkp /usr/local/lsws/conf/httpd_config.conf
            VHOSTCONF=$SERVER_ROOT/conf/vhosts/$DOMAIN/vhconf.conf

            cat >> $SERVER_ROOT/conf/httpd_config.conf <<END 

virtualhost $DOMAIN {
vhRoot                  $SITEPATH
configFile              $VHOSTCONF
allowSymbolLink         1
enableScript            1
restrained              0
setUIDMode              2
}

END
    
            mkdir -p $SERVER_ROOT/conf/vhosts/$DOMAIN/
            cat > $VHOSTCONF <<END 
docRoot                   \$VH_ROOT/
vhDomain                  $DOMAIN
enableGzip                1
errorlog  {
  useServer               1
}
accesslog $SERVER_ROOT/logs/$VH_NAME.access.log {
  useServer               0
  logHeaders              3
  rollingSize             100M
  keepDays                30
  compressArchive         1
}
index  {
  useServer               0
  indexFiles              index.html, index.php
  autoIndex               0
  autoIndexURI            /_autoindex/default.php
}
errorpage 404 {
  url                     /404.html
}
expires  {
  enableExpires           1
}
accessControl  {
  allow                   *
}
rewrite  {
  enable                  0
  logLevel                0
}

END
            chown -R lsadm:lsadm $SERVER_ROOT/conf/
        fi
        
        
    else
        echoR "$SERVER_ROOT/conf/httpd_config.conf is missing."
        ALLERRORS=1
    fi
}


fn_usage() {
    echoY "USAGE:                             " "$0 [options] [options] ..."
    echoY "OPTIONS                            "
    echoG " --domain(-d) DOMAIN               " "To install your site with your chosen domain(option required)."
    echoG " --sitepath(-p) SITEPATH           " "To specify a location for the new site installation(option required)."
    echoG " --email(-e) SITEPATH              " "To specify an email for SSL installation(option required)."
    echoG " --quiet                           " "Set to quiet mode, won't prompt to input anything."
    echoG " --help(-h)                        " "To display usage."
    echo
    echoY "EXAMPLE                           "
    echoG "./olsdomain -d mysite.com -e myemail@myprovider.com -p /home/myuser/www"  ""
    echo  "                                   To install your site \"mysite.com\" in the \"/home/myuser/www\" server folder and use your email \"myemail@myprovider.com\" for SSL certificate."
    echo
}

while [ "$1" != "" ] ; do
    case $1 in 
        -e| --email )              
                                    shift
                                    EMAIL=$1
                                    ;;
		 
        -d| --domain )         
                                    shift
                                    DOMAIN=$1
                                    ;;
                                    
                                    
       -p| --sitepath )           
                                    shift
                                    SITEPATH=$1			
                                    ;;

                                    
             --quiet )              FORCEYES=1
                                    ;;
                                   
        
        -h| --help )                fn_usage
                                    exit 0
                                    ;;

        * )                         fn_usage
                                    exit 0
                                    ;;
    esac
    shift
done

fn_install_site
fn_config_httpd
fn_install_ssl
#fn_restart_ols
fn_test_domain

echo
echo
echo
