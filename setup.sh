#!/bin/bash

./server-setup/docker.sh
./server-setup/letsencrypt.sh
./server-setup/aws.sh
./server-setup/jenkins/setup.sh
./server-setup/llaor/api/db.sh
./server-setup/llaor/api/setup.sh
./server-setup/llaor/web/setup.sh
./server-setup/pachatary/api/db.sh
./server-setup/pachatary/api/setup.sh
./server-setup/blog/setup.sh
./server-setup/taddapp/web/setup.sh
./server-setup/nginx.sh
./server-setup/haproxy/setup.sh
