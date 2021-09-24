# aws_gcp_vpn_tf

[![Generic badge](https://img.shields.io/badge/Terraform-v0.15.1-purple.svg)](https://www.terraform.io/upgrade-guides/0-15.html)


A Terraform project to establish a site-to-site VPN Connection between AWS and GCP.

_Initially developed to privately migrate resources from AWS &#x2192; GCP._

## Prerequisites
It is assumed you have the following infrastructure/resources configured on both AWS and GCP, respectively.

### AWS
1. An existing AWS VPC & Route Table

### GCP
1. An existing GCP identity with a valid billing account

<hr>

## Variables
The following variables must be defined in one of two places:

1. For local development, set the following values in a file called `terraform.tfvars` - these are sensitive variables & this file name is explicitly ignored in the `.gitignore` file.

2. For programmatic (or local) operation, set the following variables as [Terraform environment variables](https://www.terraform.io/docs/cli/config/environment-variables.html), appending `TF_VAR_` as a prefix to each.


**Note:** All four Tunnel Preshared Keys must be different and follow [TPK naming conventions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection#tunnel1_preshared_key).  _For initial development, the Python3 `UUID.uuid4().hex` method was used to generate four unique values, ensuring no value began with the character "0" and some alphabetical characters were randomly capitalized._

**_&#x26A0; IMPORTANT:_** Check defaults for `TUNNEL1_INSIDE_CIDR`  through `TUNNEL4_INSIDE_CIDR` in `variables.tf` - change if overlapping w/other subnets in AWS.  However, if altered, you must also amend `GCP_ROUTER_IP_ADDR_1` - `GCP_ROUTER_IP_ADDR_4` and `GCP_ROUTER_PEER_IP_ADDR_1` - `GCP_ROUTER_PEER_IP_ADDR_4` to fall within the newly defined CIDRs.

<br>

```hcl

# General GCP Parameters
GCP_PROJECT    = "<GCP Project ID>"
GCP_REGION     = "<GCP Region ex. us-east1>"


# General AWS Parameters
AWS_REGION     = "<Default AWS Region ex. us-east-1"
AWS_ACCESS_KEY = "<AWS Access Key>"
AWS_SECRET_KEY = "<AWS Secret Key>"


# Required AWS Network Details
AWS_ROUTE_TABLE_ID = "<ID of AWS Route Table in VPC to be connected to>"
AWS_VPC_ID         = "<ID of AWS VPC to be connected to>"


# Four (4) Tunnel Preshared Keys
TPK_1_1 = "<Tunnel Preshared Key 1>"
TPK_1_2 = "<Tunnel Preshared Key 2>"
TPK_2_1 = "<Tunnel Preshared Key 3>"
TPK_2_2 = "<Tunnel Preshared Key 4>"
```
<hr>
<br>

## Usage & Testing
In order to run this terraform project, ensure you've followed the variable definition instructions above in the Variables section, then run the following commands in the `/terraform` subdirectory.

1. `terraform init`
2. `terraform fmt`
3. `terraform validate`
4. `terraform plan`
5. `terraform apply -auto-approve`

### Testing
To test connectivity, take the following actions:

1. Spin up an AWS EC2 Instance in a private subnet (with private IP addr only) connected via the VPN - create and download a connection key-pair 
2. Spin up a GCP Compute Engine VM with port 22 opened (with public & private IP addrs)
3. SSH into the the GCP virtual machine via the Console SSH Button: <button>**SSH &darr;**</button>
4. Upload your AWS VM key-pair to the GCE VM via the gear icon at the top left of the SSH window
5. From your GCE VM, SSH* into your AWS machine using the private IP Address, example: `$ ssh -i my_key_pair.pem ec2-user@10.0.0.1`

> \* Depending on the OS of your GCE VM, you may need to install SSH

<br>
<hr>

Helpful Links:
1. [Official GCP HA-VPN Documentation](https://cloud.google.com/architecture/build-ha-vpn-connections-google-cloud-aws)
2. [Medium article on dynamic BGP Routing AWS <--> GCP](https://oleg-pershin.medium.com/site-to-site-vpn-between-gcp-and-aws-with-dynamic-bgp-routing-7d7e0366036d)
3. [Medium article on dynamic routing with GCP Cloud Router](https://medium.com/google-cloud/dynamic-routing-with-cloud-router-9ff5c362d833)