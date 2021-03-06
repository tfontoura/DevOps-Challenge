#!/bin/bash
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin
##########################################################################
## INSTALL SCRIPT FOR DEVOPS CHALLENGE (DESAFIO.SITE)                   ##
## AUTHOR:    T. FONTOURA                                               ##
## GOAL: CONFIGURE LINUX UBUNTU WITH DOCKER CONTAINERS                  ##
##       FOR WORDPRESS AND APACHE, USING NGINX AS REVERSE PROXY.        ##
## ARQUIVO COM COMENTARIOS EM PORTUGUES: https//desafio.site/initPT.sh  ##
##########################################################################
# Check if it's root
if [[ $EUID -ne 0 ]]; then
   echo "WARNING: You don't have privileges to run this script. Use sudo." 
   exit 1
fi


# Update instance. I commented out the upgrade for this quick install.
sudo apt update
#sudo apt -y upgrade

# Stop and disable apache if it is in the system. We need port 80 for NGINX.
sudo systemctl disable apache2 && sudo systemctl stop apache2


##################################################
#  CREATE VARIABLES  #
######################
# We could input or request input for server name, user and password here. As this is a quick demonstration, I hardcoded the information in the yml.

# nginx.conf contents
__nginxconf="
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
  worker_connections 10;
}

http {
 
     fastcgi_read_timeout 240;
     fastcgi_send_timeout 240;
     fastcgi_buffers 16 16k;
     fastcgi_buffer_size 32k;


     ##
     # Basic Settings
     ##

     sendfile on;
     tcp_nopush on;
     tcp_nodelay on;

client_max_body_size 30M;
client_body_timeout   60;
client_header_timeout 60;
send_timeout          60;

     keepalive_timeout 65;
     types_hash_max_size 2048;

     include /etc/nginx/mime.types;
     default_type application/octet-stream;

     ##
     # SSL Settings
     ##

     ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
     ssl_prefer_server_ciphers on;

    gzip on;
    gzip_comp_level 5;
    gzip_min_length 256;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/svg+xml
        image/x-icon
        text/css
        text/plain
        text/x-component;    
    gzip_disable msie6;


# Default server configuration
#
server {
        listen 80 default_server;
        listen [::]:80 default_server;

    client_max_body_size 100M;

 

    location / {



        proxy_pass http://wordpressFontoura;
        #set  http://wordpressFontoura;
        #proxy_pass ;
            proxy_redirect     off;
            proxy_set_header   Host \$host;
            proxy_set_header   X-Real-IP \$remote_addr;
            proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Host \$server_name;
    }
}

}

"

#echo "$__nginxconf"

# docker-compose.yml contents
__dockercompose="
version: '3'

services:
  webserver:
    image: nginx:latest
    depends_on:
      - wordpressFontoura
    volumes:
      - /home/ubuntu/efs/conf/nginx.conf:/etc/nginx/nginx.conf:ro
#    networks:
 #     - net
    ports:
      - 80:80
    deploy:
      replicas: 1
      update_config:
        parallelism: 1
        #delay: 10s
      resources:
        limits:
            cpus: '0.25'
            memory: 75M
      restart_policy: 
        condition: always

  wordpressFontoura:
    image: wordpress:latest
    depends_on:
      - db
    restart: always
    environment:
     WORDPRESS_DB_HOST: db
     WORDPRESS_DB_USER: fonfontoura
     WORDPRESS_DB_PASSWORD: Asa345fGt
     WORDPRESS_DB_NAME: fontoura_wordpress
    volumes:
      - /home/ubuntu/efs/www:/var/www/html
 #   networks:
 #     - net
    deploy:
      replicas: 1
      update_config:
        parallelism: 1
        #delay: 10s
      resources:
        limits:
            cpus: '0.5'
            memory: 200M 

  db:
    image: mysql:5.7
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: '23Tf;yx'
      MYSQL_DATABASE: fontoura_wordpress
      MYSQL_USER: fonfontoura
      MYSQL_PASSWORD: Asa345fGt
      #MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - volumemysqldb:/var/lib/mysql
 #   networks:
 #     - net
    deploy:
      replicas: 1
      update_config:
        parallelism: 1
      resources:
        limits:
            cpus: '0.5'
            memory: 400M

#networks:
#  net:
  #  external: true
volumes:
  volumemysqldb:
    #drive: local

"

#echo "$__dockercompose"

#### END OF CREATING VARIAVEIS ###################

# The installation function
instala(){
    echo
    echo ">>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<"
    echo ">> Starting install. Please hold.   <<"
    echo ">>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<"
    echo
    
    # INSTALL DOCKER
    # We save time using a install script
    curl -fsSL https://get.docker.com | sudo bash

    # INSTALL DOCKER-COMPOSE 
    # If we want to be sure our yml is compatible with the docker compose version, we use a version we know. For this demonstration, let's use latest.
    # sudo curl -L "https://github.com/docker/compose/releases/download/v2.3.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Make it executable
     sudo chmod +x /usr/local/bin/docker-compose
     
    # Here we create path and files. For this challenge I'm putting it all under home. Ideally we'd use EFS.
    # ~/efs/
    #     |_docker/
    #     |_conf/
    #     |_www/
    

    mkdir /home/ubuntu/efs
    mkdir /home/ubuntu/efs/conf
    mkdir /home/ubuntu/efs/www
    mkdir /home/ubuntu/efs/docker

    # Change owner to www-data, so we don't have permissions issues for Apache.
    sudo chown 33:33 /home/ubuntu/efs/www
    
    # Cria arquivos
    echo "$__nginxconf"     > /home/ubuntu/efs/conf/nginx.conf
    echo "$__dockercompose" > /home/ubuntu/efs/docker/docker-compose.yml

    echo "Installing..."
    echo

       # Run docker-compose
       sudo docker-compose -f /home/ubuntu/efs/docker/docker-compose.yml up -d 

    echo
    echo "Finished installing"
    echo
    echo "Verifying..."
    echo
    sleep 5
    echo "Wait..."
    echo
    sleep 10

    
    # Get IP and finalize
       meuIP=$(curl -sS http://checkip.amazonaws.com)

       # Check if webserver is working
       out=$(curl -k -I -L -s  "$meuIP" | grep -E -i 'http/[[:digit:]]*')
 
       if [ "$out" != "" ]
       then
              if [[ $out =~ .*200.* ]] 
           then
               echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
               echo ">>         >>           S U C C E S S !          <<             <<"
               echo ">>  You can now access the server using the following address   <<"
               echo ">>                  http://"$meuIP"                        <<" 
               echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
               echo
               # At this point we could use AWS lambda to access Cloudflare API and add a DNS A register with this server IP and name. Something as http://new-server.desafio.site
               echo
               echo "And so we solved the challenge ;)"
               echo "                  - T. Fontoura"
               echo
           else
               echo "SOMETHING'S WRONG, SERVER NOT WORKING!"
               echo "Headers for $meuIP:"
               echo "$out"
           fi
       fi

echo
echo "Reminder: This server's external IP is "$meuIP

}

# We run this install from inside a function, so we have some protection in case curl doesn't download the whole file. Here we are close to EOF

instala
