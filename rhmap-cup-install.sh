
cd ./rhmap-ansible
ansible-playbook -i inventory-templates/fh-cup-example playbooks/poc.yml -e "core_templates_dir=/Users/cvicensa/Projects/openshift/rhmap-templates/4.5/fh-core-openshift-templates/generated" -e "mbaas_templates_dir=/Users/cvicensa/Projects/openshift/rhmap-templates/4.5/fh-mbaas-openshift-templates" -e "mbaas_project_name=mbaas" -e "core_project_name=core" -e "strict_mode=false" --tags deploy