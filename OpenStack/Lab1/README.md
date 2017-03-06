Introduction to the OpenStack Horizon UI
==================================

# Part 1: Logging into the Horizon UI

Use your web browser to go to [the Horizon Dashboard - https://cor00005.cni.ukcloud.com](https://cor00005.cni.ukcloud.com/)
The user credentials for this lab can be found already setup in environment variables.

- On Windows workstations, you'll find the environment variables setup in C:\Users\Administrator\openrc.cmd
- On Linux workstations, you'll find the environment variables setup in /home/ubuntu/openrc

# Part 2: [Creating SSH Key Pairs](SSH_Key_Pairs.md)

The first thing you will need to do after logging in is to setup an SSH Key Pair that will be used when launching instances. If you do not already have a pair of private / public SSH key files to hand, you will need to create one.

# Part 3: [Defining Security Groups](Security_Groups.md)
Rather than a perimeter or border firewall that might be used in traditional infrastructure, OpenStack uses per-instance firewall protection know as a Security Groups. An instance may have one or more security groups applied to it, the resulting rule set being the union of all the firewall rules defined in each group.

# Part 4: [Network Connectivity](Networking.md)
OpenStack's Software Defined Networking is provided by the Neutron service. Here we look at defining internal networks and subnets, configuring DHCP options for passing to instances, and how the neutron router allows you to interconnect internal and external networks.

# Part 5: [Launching an Instance](Launching_Instances.md)
 Having defined where to deploy our instance, how we are going to connect to it and the SSH key to use for authentication, we now have a couple more choices to make before we can launch an instance, defining what type of disk image and operating system to boot, and the resources (memory / vCPU / disk) to allocate to the instance.

# Part 6: [Associating a Floating IP Address](Floating_IP_Address.md)
Now we have an instance running, we can connect outbound to external services with the neutron router performing Source Network-Address-Translation. However to connect into the instance, we need to associate a Floating IP Address to our instance so that the router can DNAT inbound connections.  
