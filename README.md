# IaC - Using Terraform

## Deploy the infrastructuer using Terraform


## Deployment
 - Create Network with two subnets (private and public)
 - create a network security group
 - Deploy Linux virtual machine scale set + load balancer behind network security group.
 - Add Azure postgresql as a service with configured fw rules.
 


			
1. Use git clone to clone the terraform repository.
```-Verify that you can see the following files:
README.md, output.tf, variables.tf and main.tf files
```
Be aware: the staging.tfvars and prod.tfvars file will be sent via the Discord !!!

2. Create two workspaces - for production and for staging

run the commands:
 - terraform workspace new production
 - terraform workspace new staging  

3. Validate that both workspaces were created
```
run : terraform workspace list
```
4. Creating the staging environment:
```
- Run: terraform plan -var-file .\staging.tfvars
- wait until it will be finished with no errors.
- Run: terraform apply -var-file .\staging.tfvars
-The deployment should be end successfully 
- you should get output of the admin_password, current_workspace and vmss_front_ip.
```
5. Creating the production environment:
```
Run: terraform plan -var-file .\prod.tfvars
wait until it will be finished with no errors.
Run: terraform apply -var-file .\prod.tfvars
-The deployment should be end successfully 
you should get output of the admin_password, current_workspace and vmss_front_ip.
```



