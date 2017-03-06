Deploying an HA Cluster for HAProxy
===================================

UKCloud's current OpenStack deployment has deliberately not enabled the Neutron LBaaS feature. This decision was taken because the current implementation in the OpenStack ecosystem is not resilient to host failure.