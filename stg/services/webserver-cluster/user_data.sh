#!/bin/bash

cata > indedx.html <<EOF
<h1> Hello, world</h1>
<p> This is a webserver running on port ${server_port} </p>
# <p> DB addess: ${db_address} </p>
# <p> DB port: ${db_port} </p>
EOF

nohup busybox httpd -f -p ${server_port} &
