#!/bin/bash

# Use Google's Public DNS Servers
sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf

service systemd-resolved restart
