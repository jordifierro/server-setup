# Server setup

This repo contains instructions and scripts to mount a server
able to host [Llaor](https://llaor.com),
[Pachatary](https://play.google.com/store/apps/details?id=com.pachatary&hl=en),
[Taddapp](https://taddapp.com) and [my blog](https://jordifierro.com) projects.

Some projects are webs, others also has api and databases...
To minimize the amount of dependencies, everything runs with docker.
An haproxy (to load balance apis) and nginx (as static content deliverer)
handle the traffic. Postgres is used for databases (also dockerized).
Jenkins does the ci/cd and other administration jobs, hooked with github.
There are some extra pieces that are not as important as these,
so they will be explained on their projects.

Here I'll try to explain every part step by step...

## System

First of of, prepare a linux server and secure it.

Create a server with Ubuntu 20.04 (LTS) x64

Login as root on your server.

Create your user, add a password to it and make it sudoer:
```bash
useradd -m -s /bin/bash myuser
passwd myuser
usermod -aG sudo myuser
exit
```

Generate your ssh key (if not already done), add it to your server user trusted keys
and ssh into server:
```bash
ssh-keygen
ssh-copy-id myuser@serverip
ssh myuser@serverip
```

Configure and activate firewall:
```bash
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 322/tcp          # for ssh later use
sudo ufw --force enable
```

Edit ssh config to make it more secure
(close password and root login and change ssh port):
```bash
sudo vim /etc/ssh/sshd_config

------->
Port 322
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
<-------

sudo systemctl restart ssh
exit
```

Now you can log in again and delete ssh ufw rule:
```bash
ssh -p 322 myuser@serverip
sudo ufw delete allow ssh
```

## Software

There is an script to install all software
and application at a time at the end of this README.
But it can contains some errors
(script commands are applied manually and then copied into this repo, there are no tests)
and I think it's better to explain step by step.

First of all, update system software dependencies:

```bash
sudo apt update
```

### Docker

```bash
sudo apt -yq install docker.io
sudo systemctl enable --now docker
```

### Haproxy

Install haproxy:

```bash
sudo apt -yq install haproxy
systemctl start haproxy
```

### Nginx

```bash
sudo apt -yq install nginx
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl start nginx
```

### Jenkins

Install Jenkins:

```bash
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install openjdk-11-jdk-headless
sudo apt install jenkins
sudo systemctl enable --now jenkins
```

Configure nginx:

```bash
sudo cp server-setup/jenkins/nginx.conf /etc/nginx/sites-available/jenkins.jordifierro.com
sudo rm /etc/nginx/sites-enabled/jenkins.jordifierro.com
sudo ln -s /etc/nginx/sites-available/jenkins.jordifierro.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

Restore Jenkins configuration from
[server-jenkins](https://github.com/jordifierro/server-jenkins) repository
(follow more specific steps on its own README):
```bash
git clone git@github.com:jordifierro/server-jenkins.git
sudo chown -R jenkins:jenkins server-jenkins/
sudo rsync server-jenkins/ /var/lib/jenkins/
```

And finally, generate an ssh id for jenkins user and add it to github:

```bash
sudo su jenkins
ssh-keygen
exit
```

### AWS

I use AWS as database backup storage.
Install amazon web services cli:

```bash
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Copy `llaor/api/aws.env.list` from secrets repo and
configurate an aws profile for llaor:
```bash
source llaor/api/aws.env.list
aws configure set aws_access_key_id $LLAOR_AWS_ACCESS_KEY_ID --profile llaor
aws configure set aws_secret_access_key $LLAOR_AWS_SECRET_ACCESS_KEY --profile llaor
aws configure set region eu-west-1 --profile llaor
```

The same applies for pachatary (`pachatary/api/aws.env.list`):
```bash
source pachatary/api/aws.env.list
aws configure set aws_access_key_id $PACHATARY_AWS_ACCESS_KEY_ID --profile pachatary
aws configure set aws_secret_access_key $PACHATARY_AWS_SECRET_ACCESS_KEY --profile pachatary
aws configure set region eu-west-1 --profile pachatary
```

### Certbot

To request ssl certificates from letsencrypt:

```bash
sudo apt -yq install letsencrypt
```


## Applications

First, we will deploy application by application
and finally we will configure haproxy to expose them.

### Taddapp

[taddapp.com](https://taddapp.com)

This is the simplest one.
We just need to download static html code
and serve it with nginx.
Let's start!

First, add an `A Record` from your domain to the server ip.
Then, generate an ssl certificate with certbot tool:
```bash 
sudo certbot certonly --manual --preferred-challenges=dns --email=jordifierromulero@gmail.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.taddapp.com" -d taddapp.com
```

This is the nginx.conf for this project:

```bash
server {
    listen 127.0.0.1:80;

    root /var/www/jordifierro.com/html;
    index index.html index.htm index.nginx-debian.html;

    server_name jordifierro.com www.jordifierro.com;

    location / {
            try_files $uri $uri.html $uri/index.html /index.html;
    }
}
```

Setup nginx.conf:
```bash
sudo cp server-setup/taddapp/web/nginx.conf /etc/nginx/sites-available/taddapp.com
sudo rm /etc/nginx/sites-enabled/taddapp.com
sudo ln -s /etc/nginx/sites-available/taddapp.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

And finally deploy the static files under `/var/www/taddapp.com`:
```bash
# sudo rm -rf taddapp-web
# sudo rm -rf /var/www/taddapp.com/
git clone git@github.com:jordifierro/taddapp-web.git
sudo mkdir -p /var/www/taddapp.com/html
sudo chown -R $USER:$USER /var/www/taddapp.com/html
sudo mv taddapp-web/* /var/www/taddapp.com/html/
```

### Blog

[jordifierro.com][https://jordifierro.com]

This is another website but created with Jekyll
so its statics must be builded.

First, add an `A Record` from your domain to the server ip.
Then, generate an ssl certificate with certbot tool:
```bash 
sudo certbot certonly --manual --preferred-challenges=dns --email=jordifierromulero@gmail.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.jordifierro.com" -d jordifierro.com
```

This is the nginx.conf for this project:

```bash
server {
    listen 127.0.0.1:80;

    root /var/www/jordifierro.com/html;
    index index.html index.htm index.nginx-debian.html;

    server_name jordifierro.com www.jordifierro.com;

    location / {
            try_files $uri $uri.html $uri/index.html /index.html;
    }
}
```

Setup nginx.conf:
```bash
sudo cp server-setup/blog/nginx.conf /etc/nginx/sites-available/jordifierro.com
sudo rm /etc/nginx/sites-enabled/jordifierro.com
sudo ln -s /etc/nginx/sites-available/jordifierro.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

And finally build and deploy the static files under `/var/www/jordifierro.com`:
```bash
# sudo rm -rf jordifierro.github.io
git clone https://github.com/jordifierro/jordifierro.github.io.git
cd jordifierro.github.io
sudo mkdir -p .jekyll-cache _site
sudo docker run --rm -t --volume="$PWD:/srv/jekyll" --env JEKYLL_ENV=production jekyll/jekyll:3.8 bash -c "jekyll build --trace"
cd ..
# sudo rm -rf /var/www/jordifierro.com/
sudo mkdir -p /var/www/jordifierro.com/html
sudo chown -R $USER:$USER /var/www/jordifierro.com/html
sudo mv jordifierro.github.io/_site/* /var/www/jordifierro.com/html/
```
### Pachatary

[pachatary.com](https://pachatary.com)

Here we have to setup an api for pachatary android and ios applications.
It's a Django application with a database, so requires a database,
a two running instances of the app (to load balanced deployments)
and an nginx to serve static content.

#### Database

Let's start with the database.
Get `pachatary/api/db.env.list` from secrets repo and execute the following commands:
```bash
source pachatary/api/db.env.list
sudo docker volume create pachatary-pgdata
sudo docker network create pachatary-net
sudo docker run --name pachatary-postgres -e POSTGRES_PASSWORD=$PACHATARY_POSTGRES_PASSWORD -v pachatary-pgdata:/var/lib/postgresql/data --restart=always --net pachatary-net -d postgres
sudo docker exec -t pachatary-postgres psql -U postgres -c  "CREATE ROLE $PACHATARY_DB_ROLE WITH LOGIN ENCRYPTED PASSWORD '$PACHATARY_DB_ROLE_PASSWORD'"
sudo docker exec -t pachatary-postgres psql -U postgres -c  "ALTER ROLE $PACHATARY_DB_ROLE createdb"
aws s3 cp s3://pachatary-db/latest.dump latest.dump --profile pachatary
sudo docker exec -t pachatary-postgres psql -U postgres -c "drop database $PACHATARY_DB"
sudo docker exec -t pachatary-postgres psql -U postgres -c "create database $PACHATARY_DB with owner $PACHATARY_DB_ROLE"
sudo docker run --rm -v $PWD:/src -v pachatary-pgdata:/dest -w /src alpine cp latest.dump /dest
sudo docker exec -t pachatary-postgres bash -c "psql -u $PACHATARY_DB_ROLE -d $PACHATARY_DB < /var/lib/postgresql/data/latest.dump"
```

We must create a volume for data persistance and
a network for communicate with django docker instance later.
This commands also restore the latests dump saved on aws
(we can also create a new database and run django migrations).
It is not needed now but here we have the script to make a database dump and save it to aws:
```bash
source pachatary/api/db.env.list
date=$(date +%F)
sudo docker exec pachatary-postgres pg_dump -U postgres --verbose $PACHATARY_DB > $date.dump
sudo aws s3 cp $date.dump s3://pachatary-db/$date.dump --profile pachatary
sudo aws s3 cp s3://pachatary-db/$date.dump s3://pachatary-db/latest.dump --profile pachatary
```

Once we have the database up & running we must setup the api & statics servers.
For this we'll also use docker.
As I said before, this script get 2 instances of each up
(that will be load balanced from haproxy).

First of all, generate the ssl certificate:
```bash
sudo certbot certonly --manual --preferred-challenges=dns --email=jordifierromulero@gmail.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.pachatary.com" -d pachatary.com
```

Then, we'll copy the nginx confs to nginx folder.
I use sed to replace docker host names for the appropiate ones
(`pachatary-api-01` and `pachatary-api-02`):
```bash
sudo mdkir -p /etc/nginx/sites-available/api.pachatary.com
sudo cp server-setup/pachatary/api/nginx.conf /etc/nginx/sites-available/api.pachatary.com/nginx.conf
sudo sed 's/pachatary-api/pachatary-api-01/g' /etc/nginx/sites-available/api.pachatary.com/nginx.conf > /etc/nginx/sites-available/api.pachatary.com/nginx-01.conf
sudo sed 's/pachatary-api/pachatary-api-02/g' /etc/nginx/sites-available/api.pachatary.com/nginx.conf > /etc/nginx/sites-available/api.pachatary.com/nginx-02.conf
```

This nginx config files will be used later.

Finally, deploy:

```bash
# sudo rm -rf pachatary-api
git clone https://github.com/jordifierro/pachatary-api.git
cp server-setup/pachatary/api/env.list pachatary-api/
cd pachatary-api
sudo docker build -t pachatary/api .

sudo docker volume create pachatary-statics-01
sudo docker run -d --restart=always --env-file env.list --net pachatary-net -v pachatary-statics-01:/code/pachatary/staticfiles --name pachatary-api-01 -e INTERNAL_IP=127.0.1.1 -t pachatary/api
sudo docker run --name pachatary-nginx-01 -v pachatary-statics-01:/usr/share/nginx/html/static:ro -v /etc/nginx/sites-available/api.pachatary.com/nginx-01.conf:/etc/nginx/nginx.conf:ro -p 127.0.1.1:80:80 --net pachatary-net --restart=always -d nginx

sudo docker volume create pachatary-statics-02
sudo docker run -d --restart=always --env-file env.list --net pachatary-net -v pachatary-statics-02:/code/pachatary/staticfiles --name pachatary-api-02  -e INTERNAL_IP=127.0.1.2 -t pachatary/api
sudo docker run --name pachatary-nginx-02 -v pachatary-statics-02:/usr/share/nginx/html/static:ro -v /etc/nginx/sites-available/api.pachatary.com/nginx-02.conf:/etc/nginx/nginx.conf:ro -p 127.0.1.2:80:80 --net pachatary-net --restart=always -d nginx
```

We get the code from github and build its docker image.
Then, create volumes to share statics from api container to nginx container.
After that we can run api and nginx containers.
Api container will build statics on start up and nginx will get them through de volume.
Then, we repeat the process with the second container.
Be carefull with the ips, they must match with haproxy's ones!

For future deploys we can add this commands to wait for firsts containers to be ready
before restarting the second ones:
```bash
response=000
while [ $response -gt 499 -o "${response}" = 000 ]
do
    sleep 1
    response=$(curl --write-out %{http_code} --silent --output /dev/null 127.0.1.1)
    echo $response
done
```

That's it! In [server-jenkins](https://github.com/jordifierro/server-jenkins) repo
we can see more scripts to test, reindex search db, etc...


### Llaor

[llaor.com](https://llaor.com)

This project is very similar to the previous one,
but here we also have to serve a React web app.

#### Web

First, add an `A Record` from your domain to the server ip.
Then, generate an ssl certificate with certbot tool:
```bash 
sudo certbot certonly --manual --preferred-challenges=dns --email=jordifierromulero@gmail.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.llaor.com" -d llaor.com
```

This is the nginx.conf for this project:

```bash
server {
    listen 127.0.0.1:80;
    server_name www.llaor.com;
    return 301 http://llaor.com$request_uri;
}

server {
    listen 127.0.0.1:80;

    root /var/www/llaor.com/html;
    index index.html index.htm index.nginx-debian.html;

    server_name llaor.com;

    location / {
        try_files $uri /index.html =404;
    }
}
```

_`www` redirects to non-www to avoid CORS troubles on api calls._

Setup nginx.conf:
```bash
sudo cp server-setup/llaor/web/nginx.conf /etc/nginx/sites-available/llaor.com
sudo rm /etc/nginx/sites-enabled/llaor.com
sudo ln -s /etc/nginx/sites-available/llaor.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

And finally build and deploy the static files under `/var/www/llaor.com`:
```bash
# sudo rm -rf llaor-web
git clone https://github.com/jordifierro/llaor-web.git
cd llaor-web
echo $'NODE_PATH=src\nREACT_APP_API_HOST=http://llaor.herokuapp.com' > .env
sudo docker build -t llaor/web .
mkdir build
sudo docker run -v $(pwd)/build/:/usr/src/app/build/ -t llaor/web bash -c "npm run build"
cd ..
# sudo rm -rf /var/www/llaor.com/
sudo mkdir -p /var/www/llaor.com/html
sudo chown -R $USER:$USER /var/www/llaor.com/html
sudo mv llaor-web/build/* /var/www/llaor.com/html/
```

#### Database

Again, first the database.
Get `llaor/api/db.env.list` from secrets repo and execute the following commands:
```bash
source llaor/api/db.env.list
sudo docker volume create llaor-pgdata
sudo docker network create llaor-net
sudo docker run --name llaor-postgres -e POSTGRES_PASSWORD=$LLAOR_POSTGRES_PASSWORD-v llaor-pgdata:/var/lib/postgresql/data --restart=always --net llaor-net -d postgres
sudo docker exec -t llaor-postgres psql -U postgres -c  "CREATE ROLE $LLAOR_DB_ROLE WITH LOGIN ENCRYPTED PASSWORD '$LLAOR_DB_ROLE_PASSWORD'"
sudo docker exec -t llaor-postgres psql -U postgres -c  "ALTER ROLE $LLAOR_DB_ROLE createdb"
aws s3 cp s3://llaor/db/latest.dump latest.dump --profile llaor
sudo docker exec -t llaor-postgres psql -U postgres -c "drop database $LLAOR_DB"
sudo docker exec -t llaor-postgres psql -U postgres -c "create database $LLAOR_DB with owner $LLAOR_DB_ROLE"
sudo docker run --rm -v $PWD:/src -v llaor-pgdata:/dest -w /src alpine cp latest.dump /dest
sudo docker exec -t llaor-postgres bash -c "psql -U $LLAOR_DB_ROLE -d $LLAOR_DB < /var/lib/postgresql/data/latest.dump"
```

We must create a volume for data persistance and
a network for communicate with django docker instance later.
This commands also restore the latests dump saved on aws
(we can also create a new database and run django migrations).
It is not needed now but here we have the script to make a database dump and save it to aws:
```bash
source pachatary/api/db.env.list
date=$(date +%F)
sudo docker exec llaor-postgres pg_dump -U postgres --verbose $LLAOR_DB > $date.dump
sudo aws s3 cp $date.dump s3://llaor/db/$date.dump --profile llaor
sudo aws s3 cp s3://llaor/db/$date.dump s3://llaor/db/latest.dump --profile llaor
```

#### Api

Once we have the database up & running we must setup the api & statics servers.
For this we'll also use docker.
As I said before, this script get 2 instances of each up
(that will be load balanced from haproxy).


We'll copy the nginx confs to nginx folder.
I use sed to replace docker host names for the appropiate ones
(`llaor-api-01` and `llaor-api-02`):
```bash
sudo mdkir -p /etc/nginx/sites-available/api.llaor.com
sudo cp server-setup/llaor/api/nginx.conf /etc/nginx/sites-available/api.llaor.com/nginx.conf
sudo sed 's/llaor-api/llaor-api-01/g' /etc/nginx/sites-available/api.llaor.com/nginx.conf > /etc/nginx/sites-available/api.llaor.com/nginx-01.conf
sudo sed 's/llaor-api/llaor-api-02/g' /etc/nginx/sites-available/api.llaor.com/nginx.conf > /etc/nginx/sites-available/api.llaor.com/nginx-02.conf
```

This nginx config files will be used later.

Finally, deploy:

```bash
# sudo rm -rf llaor-api
git clone https://github.com/jordifierro/llaor-api.git
cp server-setup/llaor/api/env.list llaor-api/
cd llaor-api

sudo docker build -t llaor/api .

sudo docker volume create llaor-statics-01
sudo docker run -d --restart=always --env-file env.list --net llaor-net -v llaor-statics-01:/code/llaor/staticfiles --name llaor-api-01 -t llaor/api
sudo docker run --name llaor-nginx-01 -v llaor-statics-01:/usr/share/nginx/html/static:ro -v /etc/nginx/sites-available/api.llaor.com/nginx-01.conf:/etc/nginx/nginx.conf:ro -p 127.0.0.2:80:80 --net llaor-net --restart=always -d nginx


sudo docker volume create llaor-statics-02
sudo docker run -d --restart=always --env-file env.list --net llaor-net -v llaor-statics-02:/code/llaor/staticfiles --name llaor-api-02 -t llaor/api
sudo docker run --name llaor-nginx-02 -v llaor-statics-02:/usr/share/nginx/html/static:ro -v /etc/nginx/sites-available/api.llaor.com/nginx-02.conf:/etc/nginx/nginx.conf:ro -p 127.0.0.3:80:80 --net llaor-net --restart=always -d nginx
```

Same pachatary deployment strategy applied here.


### Haproxy

Finally, we must configure haproxy to work as a proxy for the applications.
Copy haproxy.cfg file from this repo to `etc/haproxy/haproxy.cfg`:

```bash
sudo cp server-setup/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
```

How does it works?

```bash
global
	log /dev/log	local0
	log /dev/log	local1 notice
	chroot /var/lib/haproxy
	stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
	stats timeout 30s
	user haproxy
	group haproxy
	daemon

	# Default SSL material locations
	ca-base /etc/ssl/certs
	crt-base /etc/ssl/private

	# See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
	log	global
	mode	http
	option	httplog
	option	dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
	errorfile 400 /etc/haproxy/errors/400.http
	errorfile 403 /etc/haproxy/errors/403.http
	errorfile 408 /etc/haproxy/errors/408.http
	errorfile 500 /etc/haproxy/errors/500.http
	errorfile 502 /etc/haproxy/errors/502.http
	errorfile 503 /etc/haproxy/errors/503.http
	errorfile 504 /etc/haproxy/errors/504.http

frontend jordifierro
        bind SERVER_IP:80
        bind SERVER_IP:443 ssl crt /etc/haproxy/certs/jordifierro.com.pem crt /etc/haproxy/certs/llaor.com.pem crt /etc/haproxy/certs/pachatary.com.pem crt /etc/haproxy/certs/taddapp.com.pem
        redirect scheme https code 301 if !{ ssl_fc }
        mode http
        option forwardfor header X-Real-IP
        acl is_llaor_api hdr_dom(host) -i api.llaor.com
        acl is_pachatary_api hdr_dom(host) -i api.pachatary.com
        acl is_pachatary_api hdr_dom(host) -i pachatary.com
        use_backend llaor_api if is_llaor_api
        use_backend pachatary_api if is_pachatary_api
        default_backend nginx

backend nginx
        mode http
        server nginx 127.0.0.1:80

backend llaor_api
        mode http
        option httpchk
        http-check expect ! rstatus ^5
        server llaor_server_01 127.0.0.2:80 check
        server llaor_server_02 127.0.0.3:80 check

backend pachatary_api
        mode http
        option httpchk
        http-check expect ! rstatus ^5
        server pachatary_server_01 127.0.1.1:80 check
        server pachatary_server_02 127.0.1.2:80 check
```

This haproxy config has 3 paths.
The default one redirects to nginx (for taddapp.com and jordifierro.com),
where each server config will serve appropriate files.
The other 2 paths are for llaor.com and pachatary.com domains.
Both load balance the requests to two different internal servers (dockerized nginx servers)
with the intention of achieve zero-downtime deployments.

The last step is to copy the domain certifications to `haproxy/certs` folder
with the desired format:

```bash
sudo mkdir -p /etc/haproxy/certs
sudo cat /etc/letsencrypt/live/pachatary.com/fullchain.pem /etc/letsencrypt/live/pachatary.com/privkey.pem > /etc/haproxy/certs/pachatary.com.pem
sudo cat /etc/letsencrypt/live/llaor.com/fullchain.pem /etc/letsencrypt/live/llaor.com/privkey.pem > /etc/haproxy/certs/llaor.com.pem
sudo cat /etc/letsencrypt/live/jordifierro.com/fullchain.pem /etc/letsencrypt/live/jordifierro.com/privkey.pem > /etc/haproxy/certs/jordifierro.com.pem
sudo cat /etc/letsencrypt/live/taddapp.com/fullchain.pem /etc/letsencrypt/live/taddapp.com/privkey.pem > /etc/haproxy/certs/taddapp.com.pem
```

Let's restart haproxy to apply changes:
```bash
systemctl restart haproxy
```

## Installation script

If you want to try to install software and
applications at a time follow this steps:

Generate a ssh key from inside the server and introduce it to your github:
```bash
ssh-keygen
```

Clone this repo from your server,
accepting github as trusted server and
introducing your ssh key passphrase:
```bash
git clone git@github.com:jordifierro/server-setup.git
```

Prepare for a non-interactive script:
```bash
export DEBIAN_FRONTEND=noninteractive
```

Replace `llaor/api/env.list`, `llaor/api/aws.env.list`, `llaor/api/db.env.list`,
`pachatary/api/env.list`, `pachatary/api/aws.env.list`, `pachatary/api/db.env.list`
files from secrets repo ones.

Replace `SERVER_IP` string with real public server ip on `haproxy/haproxy.cfg` file.

Execute setup script:
```bash
./server-setup/setup.sh
```
