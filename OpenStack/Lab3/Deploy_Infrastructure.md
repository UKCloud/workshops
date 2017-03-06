Automating the Infrastructure Deployment
========================================

The HEAT Orchestration Template files allow you to describe every component of your OpenStack infrastructure as code. The file can then be upload to the HEAT service in OpenStack, and OpenStack will step through each resource defined in the template and create / update it for you in your project. The result of creating all the resources is a 'Stack'. The stack can be updated by applying newer versions of the HEAT template, or it can be deleted, thus removing all the resources originally defined by the HEAT template.

The HEAT template can be uploaded either through the Horizon UI, or by using the CLI tools. Horizon is limited to launching simple stacks that only consist of a single file. By using the CLI tools, your HEAT templates can be a lot more complex and pull in resources defined across multiple files.

This lab will only make use of the CLI tools.

## Clearing up your project

The ```infrastructure.yml``` file is an example showing how to automate the creation of the network resources we built by hand in Lab 1. Before you use this file, you should clear out the existing resources from your openstack project. The following commands should help you:

``` bash
openstack server delete jumpbox01 webserver-1 webserver-2 webserver-3 webserver-4 webserver-5
openstack router remove subnet InternetGW internal-subnet
openstack router remove subnet InternetGW dmz-subnet
openstack subnet delete internal-subnet dmz-subnet
openstack network delete Internal DMZ
openstack router delete InternetGW
openstack security group delete ExternalSSH InternalSSH
```

## Deploying your infrastructure

Now to upload and apply the ```infrastructure.yml``` file to our clean project, run:

``` bash
openstack stack create -t infrastructure.yml --wait Infrastructure
```

This will upload the file and then wait polling for any events occuring during the stack creation until it completes. You could miss off the ```--wait``` parameter and it will submit the file asynchronously and exit immediately. You can then watch the progress either through the Horizon UI, or by running:

``` bash
openstack stack event list --follow Infrastructure
```

## Updating your infrastructure

Edit the ```infrastructure.yml``` file and add new security group to allow http (tcp port 80) traffic from anywhere on the internet.

Once you have updated the file, you can use it to update the Infrastructure stack by running:

``` bash
openstack stack update -t infrastructure.yml --wait Infrastructure
```

## Cleaning out your Project

Now that you are automating the build of your network resources, you can also benefit from the ease of cleaning up again. By deleting the stack, it will automatically remove all the resources that were build in the creation of the stack. 

To clean out your project, you can now run:

``` bash
openstack stack delete --wait Infrastructure
```