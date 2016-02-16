variable "vcd_org"        {}
variable "vcd_userid"     {}
variable "vcd_pass"       {}
variable "catalog"        { default = "DevOps" }
variable "vapp_template"  { default = "centos71" }
variable "edge_gateway"   { default = "Edge Gateway Name" }
variable "jumpbox_ext_ip" {}
variable "mgt_net_cidr"   { default = "10.10.0.0/24" }
variable "web_net_cidr"   { default = "10.20.0.0/24" }
variable "jumpbox_int_ip" { default = "10.10.0.100" }
variable "haproxy_int_ip" { default = "10.20.0.10" }
variable "webserver_count" { default = 2 }
 
# Configure the VMware vCloud Director Provider
provider "vcd" {
    user            = "${var.vcd_userid}"
    org             = "${var.vcd_org}"
    password        = "${var.vcd_pass}"
    url             = "https://api.vcd.portal.skyscapecloud.com/api"
}

# Create our networks
resource "vcd_network" "mgt_net" {
    name         = "Management Network"
    edge_gateway = "${var.edge_gateway}"
    gateway      = "${cidrhost(var.mgt_net_cidr, 1)}"

    static_ip_pool {
        start_address = "${cidrhost(var.mgt_net_cidr, 10)}"
        end_address   = "${cidrhost(var.mgt_net_cidr, 200)}"
    }
}

resource "vcd_network" "web_net" {
    name         = "Webserver Network"
    edge_gateway = "${var.edge_gateway}"
    gateway      = "${cidrhost(var.web_net_cidr, 1)}"

    static_ip_pool {
        start_address = "${cidrhost(var.web_net_cidr, 10)}"
        end_address   = "${cidrhost(var.web_net_cidr, 200)}"
    }
}

# Jumpbox VM on the Management Network
resource "vcd_vapp" "jumpbox" {
    name          = "jump01"
    catalog_name  = "${var.catalog}"
    template_name = "${var.vapp_template}"
    memory        = 512
    cpus          = 1
    network_name  = "${vcd_network.mgt_net.name}"
    ip            = "${var.jumpbox_int_ip}"

    connection {
        host = "${var.jumpbox_ext_ip}"
        user = "${var.ssh_user}"
        password = "${var.ssh_password}"
    }

    provisioner "chef"  {
        run_list = ["chef-client","chef-client::config","chef-client::delete_validation"]
        node_name = "${vcd_vapp.jumpbox.name}"
        server_url = "https://api.chef.io/organizations/${var.chef_organisation}"
        validation_client_name = "${var.chef_organisation}-validator"
        validation_key = "${file("~/.chef/skyscapecloud-validator.pem")}"
        version = "${var.chef_client_version}"
    }
}

# Webserver VMs on the Webserver network
resource "vcd_vapp" "webservers" {
    name          = "${format("web%02d", count.index + 1)}"
    catalog_name  = "${var.catalog}"
    template_name = "${var.vapp_template}"
    memory        = 1024
    cpus          = 1
    network_name  = "${vcd_network.web_net.name}"
    ip            = "${cidrhost(var.web_net_cidr, count.index + 100)}"

    depends_on    = [ "vcd_vapp.jumpbox" ]

    count         = "${var.webserver_count}"

    connection {
        bastion_host     = "${var.jumpbox_ext_ip}"
        bastion_user     = "${var.ssh_user}"
        bastion_password = "${var.ssh_password}"

        host     = "${cidrhost(var.web_net_cidr, count.index + 100)}"
        user     = "${var.ssh_user}"
        password = "${var.ssh_password}"
    }

    provisioner "chef"  {
        run_list = [ "chef-client", "chef-client::config", "chef-client::delete_validation", "my_web_app" ]
        node_name = "${format("web%02d", count.index + 1)}"
        server_url = "https://api.chef.io/organizations/${var.chef_organisation}"
        validation_client_name = "${var.chef_organisation}-validator"
        validation_key = "${file("~/.chef/${var.chef_organisation}-validator.pem")}"
        version = "${var.chef_client_version}"
        attributes {
            "tags" = [ "webserver" ]
        }
    }            
}

# Load-balancer VM on the Webserver network
resource "vcd_vapp" "haproxy" {
    name          = "lb01"
    catalog_name  = "${var.catalog}"
    template_name = "${var.vapp_template}"
    memory        = 1024
    cpus          = 1
    network_name  = "${vcd_network.web_net.name}"
    ip            = "${var.haproxy_int_ip}"

    depends_on    = [ "vcd_vapp.jumpbox" ]

    provisioner "chef"  {
        run_list = [ "chef-client", "chef-client::config", "chef-client::delete_validation", "my_web_app::load_balancer" ]
        node_name = "${vcd_vapp.haproxy.name}"
        server_url = "https://api.chef.io/organizations/${var.chef_organisation}"
        validation_client_name = "${var.chef_organisation}-validator"
        validation_key = "${file("~/.chef/${var.chef_organisation}-validator.pem")}"
        version = "${var.chef_client_version}"
        connection {
            bastion_host     = "${var.jumpbox_ext_ip}"
            bastion_user     = "${var.ssh_user}"
            bastion_password = "${var.ssh_password}"

            host     = "${var.haproxy_int_ip}"
            user     = "${var.ssh_user}"
            password = "${var.ssh_password}"
        }
    }        
}

# Inbound SSH to the Jumpbox server
resource "vcd_dnat" "jumpbox-ssh" {
    edge_gateway  = "${var.edge_gateway}"
    external_ip   = "${var.jumpbox_ext_ip}"
    port          = 22
    internal_ip   = "${var.jumpbox_int_ip}"
}

# Inbound HTTP to the loadbalancer server
resource "vcd_dnat" "loadbalance-http" {
    edge_gateway  = "${var.edge_gateway}"
    external_ip   = "${var.jumpbox_ext_ip}"
    port          = 80
    internal_ip   = "${var.haproxy_int_ip}"
}

# SNAT Outbound traffic
resource "vcd_snat" "mgt-outbound" {
    edge_gateway  = "${var.edge_gateway}"
    external_ip   = "${var.jumpbox_ext_ip}"
    internal_ip   = "${var.mgt_net_cidr}"
}

resource "vcd_snat" "web-outbound" {
    edge_gateway  = "${var.edge_gateway}"
    external_ip   = "${var.jumpbox_ext_ip}"
    internal_ip   = "${var.web_net_cidr}"
}

resource "vcd_firewall_rules" "website-fw" {
    edge_gateway   = "${var.edge_gateway}"
    default_action = "drop"

    rule {
        description      = "allow-jumpbox-ssh"
        policy           = "allow"
        protocol         = "tcp"
        destination_port = "22"
        destination_ip   = "${var.jumpbox_ext_ip}"
        source_port      = "any"
        source_ip        = "any"
    }

    rule {
        description      = "allow-loadbalancer-http"
        policy           = "allow"
        protocol         = "tcp"
        destination_port = "80"
        destination_ip   = "${var.jumpbox_ext_ip}"
        source_port      = "any"
        source_ip        = "any"
    }

    rule {
        description      = "allow-mgt-outbound"
        policy           = "allow"
        protocol         = "any"
        destination_port = "any"
        destination_ip   = "any"
        source_port      = "any"
        source_ip        = "${var.mgt_net_cidr}"
    }

    rule {
        description      = "allow-web-outbound"
        policy           = "allow"
        protocol         = "any"
        destination_port = "any"
        destination_ip   = "any"
        source_port      = "any"
        source_ip        = "${var.web_net_cidr}"
    }
}
