#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <core_templates_dir> <mbaas_templates_dir>"
    exit 1
fi

# Default: /Users/cvicensa/Projects/openshift/rhmap-templates/4.5/fh-core-openshift-templates/generated
core_templates_dir=$1
# Default: /Users/cvicensa/Projects/openshift/rhmap-templates/4.5/fh-mbaas-openshift-templates
mbaas_templates_dir=$2

cd ./rhmap-ansible
ansible-playbook -i inventory-templates/fh-cup-example playbooks/poc.yml -e "core_templates_dir=$core_templates_dir" -e "mbaas_templates_dir=$mbaas_templates_dir" -e "mbaas_project_name=mbaas" -e "core_project_name=core" -e "strict_mode=false" --tags deploy