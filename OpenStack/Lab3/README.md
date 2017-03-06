Deploying infrastructure with OpenStack HEAT
============================================

The OpenStack ecosystem includes an orchestration system called HEAT. The service is compatible with AWS CloudFormations and will often apply a CloudFormations json file without modifications. The typical file format used with the HEAT orchestration service is a YAML structure.

The OpenStack HEAT Orchestration Template format is [documented online - https://docs.openstack.org/developer/heat/template_guide/](https://docs.openstack.org/developer/heat/template_guide/)

# Part 1: [Automating the Infrastructure Deployment](Deploy_Infrastructure.md)

Deploy the networks and security groups used in Lab 1 using HEAT Orchestration.

# Part 2: [Deploying a Load-Balancer](Deploy_LoadBalancer.md)

Using HEAT Templates to deploy an HA Cluster running HAProxy.


