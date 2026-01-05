#!/bin/bash

cat > index.html <<EOF
<h1> Hello, world</h1>
<p> This is a webserver running on port ${server_port} </p>
EOF

nohup busybox httpd -f -p ${server_port} &
