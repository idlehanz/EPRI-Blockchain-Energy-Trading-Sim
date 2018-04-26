#!/usr/bin/sh

# Ensure no traffic is forwarded to outside networks
iptables -t filter -A FORWARD -o wlan0 -j DROP
iptables -t filter -A FORWARD -i wlan0 -j DROP

# Don't let Docker containers outside
iptables -A DOCKER -i wlan0 -j DROP
iptables -A DOCKER -o wlan0 -j DROP
