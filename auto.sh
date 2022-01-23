#!/usr/bin/bash

#here we have created the script for non root user for setting up the environment

##taking the root password from the user
read -p "/nEnter your root password : " root

##taking app password for cloning 

read -p "/nEnter your app password for git cloning : " apppass

##Setting the tomcat9 server 

echo "$root" |sudo -S apt update 
sudo apt-get install -y openjdk-8-jre tomcat9 openjdk-8-jdk maven

# updating the java version 
sudo update-java-alternatives --set /usr/lib/jvm/java-1.8.0-openjdk-amd64 &> /dev/null

#Following config would be required to control the heap size and set the debugging port:

tee /usr/share/tomcat9/bin/setenv.sh << EOF
export CATALINA_OPTS="-Xms256m -Xmx512M -XX:MaxPermSize=256m"
export UMASK=0022
export CATALINA_OPTS="$CATALINA_OPTS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"
EOF


#restarting the tomcat9
if sudo systemctl restart tomcat9 &>/dev/null
then
  echo "tomcat9 started successfully"
else
   sudo systemctl restart tomcat9
   exit   
fi


# opening the page 
if curl http://localhost:8080/ &>/dev/null
then
     curl http://localhost:8080/
     echo "page is opening"
else
     sudo apt install curl -y
     curl http://localhost:8080/
fi


#Installing the Elasticsearch 

wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.8.22.deb

sudo dpkg -i elasticsearch-6.8.22.deb

if sudo systemctl status elasticsearch &>/dev/null
then
   echo "service running"
else
   sudo systemctl start elasticsearch
fi     	

sleep 30s

#checking if elasticsearch is properly working 

if curl -XGET http://localhost:9200 &>/dev/null
then
   echo "Elasticsearch run successfully"
else
   curl -XGET http://localhost:9200   
fi   

#Installing Git
sudo apt install git -y 


#making the directory and cloning the dev-env-setup

read -p "Enter the name of directory with path u want to clone dev-env-setup repo : " dir

if ls $dir &> /dev/null
then
   cd $dir;git clone https://pranay1603:$apppass@bitbucket.org/senpiper/dev-env-setup.git
else
   mkdir -p $dir;cd $dir;git clone https://pranay1603:$apppass@bitbucket.org/senpiper/dev-env-setup.git
fi  	



#making the apt repo first for cassandra 
echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
 
wget -q -O - https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -

if sudo apt update &>/dev/null
 then
     echo "apt update done successfully"
 else
     sudo apt install ca-certificates -y
     sudo apt update
     echo "updated successfully"
 fi


# Installing Cassandra 
sudo apt install cassandra -y


# Index plugin copy over to /usr/share/cassandra/lib directory
sudo cp $dir/dev-env-setup/cassandra/cassandra-lucene-index-plugin-3.11.3.0.jar /usr/share/cassandra/lib/

# Restart the service:
if sudo systemctl restart cassandra &>/dev/null
then
  echo "cassandra restarted successfully"
else
    sudo systemctl restart cassandra
    exit    
fi


# cloning the core repo from bitbucket
cd $dir/ ;git clone https://pranay1603:$apppass@bitbucket.org/senpiper/core.git


#creating the core keyspace in cassandra 
# Load the keyspaces
cqlsh -e "CREATE KEYSPACE core WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'}  AND durable_writes = true;"
cqlsh -k core -f "$dir/core/CQL Scripts/DDL Script.sql"
cqlsh -f $dir/dev-env-setup/cassandra/attendance.cql



#Building Rabbitmq server
#creating apt repos for installing rabbitmq 

sudo apt install software-properties-common -y
wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -

echo "deb https://packages.erlang-solutions.com/ubuntu focal contrib" | sudo tee /etc/apt/sources.list.d/rabbitmq.list

sudo apt update
sudo apt install erlang -y

curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh | sudo bash

sudo apt update

sudo apt install rabbitmq-server -y


#enabling the plugins in rabbit mq

sudo rabbitmq-plugins enable rabbitmq_management

# Enabling management, default username and password for the interface is guest and guest respectively, we need to change it.

sudo rabbitmqctl add_user rabbitmq rabbitmq

sudo rabbitmqctl set_user_tags rabbitmq administrator

sudo rabbitmqctl set_permissions -p / rabbitmq ".*" ".*" ".*"

if sudo systemctl status rabbitmq-server &>/dev/null
then
   echo "RabbitMQ running successfully"
else
   sudo systemctl status rabbitmq-server
   exit   
fi

# building the openresty app gateway 

# creating the apt repo for openresty app agteway 
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 97DB7443D5EDEB74

sudo apt-get -y install --no-install-recommends  wget

wget -O - https://openresty.org/package/pubkey.gpg | apt-key add -

echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" |sudo tee /etc/apt/sources.list.d/openresty.list

sudo apt-get update

#installing the openresty app gateway 

sudo apt-get -y install --no-install-recommends openresty

# Copying the web configurations:

sudo cp -a $dir/dev-env-setup/openresty/* /etc/openresty/

if sudo systemctl status openresty &>/dev/null
then
  echo "openresty started successfully"
else
    sudo systemctl status openresty
    exit    
fi
#Building the redis server 

sudo apt install redis-server -y
if sudo systemctl status redis &>/dev/null
then
  echo "redis started successfully"
else
   sudo systemctl status redis
   exit   
fi


#Bundling-up everything

#cloning the common repo from bitbucket

cd $dir;git clone https://pranay1603:$apppass@bitbucket.org/senpiper/common.git

#building up the jar file 
cd $dir/common/ ; mvn -T4C clean install 


#now building the war file of core 
cd $dir/core/ ; mvn -T4C clean install

#cloning the search repo from bitbicket
cd $dir ; git clone https://pranay1603:$apppass@bitbucket.org/senpiper/search.git

#building the war file from search directory 
cd $dir/search/search/ ; mvn -T4C clean install 

#cloning the webclient repo from bitbucket
cd $dir ;git clone https://pranay1603:$apppass@bitbucket.org/senpiper/webclient.git

##switching to the latestProdBuild branch in webclient
cd $dir/webclient/;git checkout latestProdBuild

#copying the core and search war file into tomcat webapps directory 

echo "$root" |sudo -S cp $dir/core/target/core.war $dir/search/search/target/search.war /var/lib/tomcat9/webapps/

#restarting the tomcat9 service 

if sudo systemctl restart tomcat9 &>/dev/null
then
   echo "tomcat9 restarted successfully"
else
   sudo systemctl restart tomcat9
   exit   
fi

#Creating the directory for frontend & copying the webclient data to html directory
if ls /usr/share/nginx/html/excel/ &>/dev/null
then
  sudo  cp -r $dir/webclient/* /usr/share/nginx/html/
else   
    sudo mkdir -p /usr/share/nginx/html/excel/
    sudo cp -r $dir/webclient/* /usr/share/nginx/html/
fi


#installing mkcert

echo "$root" |sudo -S apt install libnss3-tools -y
wget https://github.com/FiloSottile/mkcert/releases/download/v1.1.2/mkcert-v1.1.2-linux-amd64
mv mkcert-v1.1.2-linux-amd64 mkcert
echo "$root" |sudo -S chmod +x mkcert
echo "$root" |sudo -S cp mkcert /usr/local/bin/
mkcert -install
mkcert local.senpiper.com *.local.senpiper.com localhost 127.0.0.1 ::1		

#switching to repo user to do entry into the /etc/host file

echo "$root" |sudo -S sed -i 's/\(^127.0.0.1.*\)/\1\tdevsetup.local.senpiper.com/g' /etc/hosts

#copying the certificates into the openresty folder 
sudo cp ./local.senpiper.com+4.pem /etc/openresty/ssl/fullchain.pem

sudo cp ./local.senpiper.com+4-key.pem /etc/openresty/ssl/privkey.pem

#making the directory for log storing
if ls /var/log/nginx/ &>/dev/null
then
   echo "directory exist /var/log/nginx/"
else   
  sudo mkdir /var/log/nginx/
fi

#checking the configuration
if openresty -t &>/dev/null
then
   echo "configuration check successfully of openresty"
   sudo systemctl restart openresty 
else
  sudo  openresty -t 
fi  


## creating the company file to add into cassandra db
read -p "Enter the company name : " company

read -p "Enter the subdomain of company : " subdomain

read -p "Enter the mobile no of company : " mobile

read -p "Enter the mail id of company : " mail

cp $dir/dev-env-setup/cassandra/queries $dir/$company.txt

sed -i "s/Pawan/$company/g" $dir/$company.txt

sed -i "s/pawan@senpiper.com/$mail/g" $dir/$company.txt

sed -i "s/8808808800/$mobile/g" $dir/$company.txt

sed -i  "s/[S,s]etup/$subdomain/g" $dir/$company.txt

#Creating entry into the cassandra db

cqlsh -k core -f $dir/$company.txt

