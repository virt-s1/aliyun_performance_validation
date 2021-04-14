#!/bin/bash

tmpfile=$(mktemp)
ansible-playbook ./show_instance_info.yml &>$tmpfile
# Ex. "instances_facts.instances[0].public_ip_address": "39.105.175.9"
grep public_ip_address $tmpfile | cut -d '"' -f 4 | tee ./inventory
rm -f $tmpfile
