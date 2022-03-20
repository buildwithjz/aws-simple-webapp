# aws-simple-webapp

This repository contains a Terraform configuration that demonstrates the creation of a simple, single-page 'Hello World' website hosted in AWS.

The main components of this system are 

## Setup 

This setup assumes you have an active AWS account. Ensure that your AWS credentials are loaded to your default profile on your local machine. You can verify that AWS is fully set up using

```
$ aws sts get-caller-identity
```

Otherwise, refer to the following documentation to get set up with AWS CLI locally: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html

## Components

### Networking

This setup contains all its networking within a VPC, in a two-zone public/private setup in accordance with AWS's reference architecture: 

https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html#VPC_Scenario2_Routing.

This is achieved using the official AWS terraform VPC module:

https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest

Additionally, to allow incoming traffic from the internet, this setup uses a **networking load balancer** in SSL passthrough mode (i.e. no TLS/SSL termination at the load balancer, and traffic is encrypted until it reaches the instance)

### Compute

To serve the webpage, an Ubuntu EC2 instance running nginx is used. The startup script (UserData) that is run when the instance is launched performs the following:
* Ensures that nginx and openssl are installed
* Creates the site root for a custom site with a `Hello World` in an `index.html` page.
* Creates a self-signed certificate for the DNS name of the network load balancer
* Creates a new site in nginx that listens on port 443 and terminates the SSL certificates created previously

