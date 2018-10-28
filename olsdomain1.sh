#!/bin/bash


#Site settings
INSTALLSITE=0
SITEPATH=
DOMAIN=*
EMAIL=

SERVER_ROOT=/usr/local/lsws

FORCEYES=0
ALLERRORS=0

ACTION=INSTALL
FOLLOWPARAM=

MYGITHUBURL=https://raw.githubusercontent.com/olsscripts/olssite/master/olssite.sh

VIRTHOST=$(ps -ef | awk '{for (I=1;I<=NF;I++) if ($I == "virtualhost") {printf $(I+1)};}' /usr/local/lsws/conf/httpd_config.conf)

fn_install_site() {
    if [ ! -e "$SITEPATH" ] ; then 
        mkdir -p $SITEPATH
		
	    wget -P $SITEPATH https://github.com/olsscripts/olssite/raw/master/sitefiles.tar.gz
	    cd $SITEPATH
	    tar -xzf sitefiles.tar.gz
	    rm sitefiles.tar.gz
	    mv $SITEPATH/logs $SITEPATH
	    chown -R nobody:nobody $SITEPATH
	   
    else
        echoY "$SITEPATH exists, it will be used."
    fi
}

fn_install_ssl() {
        #SSL INSTALL#
        systemctl stop lsws
        /usr/bin/certbot-auto certonly --standalone -n --preferred-challenges http --agree-tos --expand --email $EMAIL -d $DOMAIN,$VIRTHOST
        systemctl start lsws
		
}	

fn_config_httpd() {
    if [ -e "$SERVER_ROOT/conf/httpd_config.conf" ] ; then
        cat $SERVER_ROOT/conf/httpd_config.conf | grep "virtualhost $DOMAIN" >/dev/null
        if [ $? != 0 ] ; then
            sed -i -e "s/adminEmails/adminEmails $EMAIL\n#adminEmails/" "$SERVER_ROOT/conf/httpd_config.conf"
            sed -i -e "s/ls_enabled/ls_enabled   1\n#/" "$SERVER_ROOT/conf/httpd_config.conf"
	    sed -i '/listener\b/a \ \ map                     $DOMAIN $DOMAIN' -i.bkp /usr/local/lsws/conf/httpd_config.conf
            sed -i '/map                      Example */d' -i.backup /usr/local/lsws/conf/httpd_config.conf
            sed -i '/map                     Example */d' /usr/local/lsws/conf/httpd_config.conf
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
suspendedVhosts           Example
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
        echoR "$SERVER_ROOT/conf/httpd_config.conf is missing. It appears that something went wrong during OpenLiteSpeed installation."
        ALLERRORS=1
    fi
}


fn_usage() {
    echoY "USAGE:                             " "$0 [options] [options] ..."
    echoY "OPTIONS                            "
    echoG " --site(-s) DOMAIN             " "To install and setup your site with your chosen domain."
    echoG " --sitepath SITEPATH               " "To specify a location for the new site installation or use an existing site installation."
    echoG " --quiet                           " "Set to quiet mode, won't prompt to input anything."
    echoG " --help(-h)                        " "To display usage."
    echo
    echoY "EXAMPLES                           "
    echoG "./ols1clk.sh                       " "To install the latest version of OpenLiteSpeed with a random WebAdmin password."
    echoG "./olsdomain --site my2nddomain.com --sitepath /home/myuser/wwww"  ""
    echoG "./ols1clk.sh -a 123 -r 1234 --wordpressplus a.com"  ""
    echo  "                                   To install OpenLiteSpeed with a fully configured WordPress installation at \"a.com\" using WebAdmin password \"123\" and MySQL root password \"1234\"."
    echoG "./ols1clk.sh -a 123 -r 1234 --wplang zh_CN --sitetitle mySite --wordpressplus a.com"  ""
    echo  "                                   To install OpenLiteSpeed with a fully configured Chinese (China) language WordPress installation at \"a.com\" using WebAdmin password \"123\",  MySQL root password \"1234\", and WordPress site title \"mySite\"."
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
                                    
                                    
       -s| --sitepath )           
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

echo
echo
echo
