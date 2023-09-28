terraform {
  backend "s3" { }
}

provider "aws" { }

### Static resources

module "network" {
  source = "./modules/network"

  region          = var.region
  project         = var.project
  env             = var.env
  cidr_vpc        = var.cidr_vpc
  cidr_private_a  = var.cidr_private_a
  cidr_private_b  = var.cidr_private_b
  cidr_public_a   = var.cidr_public_a
  cidr_public_b   = var.cidr_public_b
}

module "bastion" {
  source = "./modules/bastion"

  project               = var.project
  env                   = var.env
  bastion_ami_id        = var.bastion_ami_id
  bastion_instance_type = var.bastion_instance_type
  bastion_storage_size  = var.bastion_storage_size
  key_name              = var.key_name
  vpc_id                = module.network.vpc_id
  subnet-public-a_id    = module.network.subnet-public-a_id
}

module "datastore" {
  source = "./modules/datastore"
  
  project = var.project
  env     = var.env
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  project             = var.project
  env                 = var.env
  vpc_id              = module.network.vpc_id
  subnet-public-a_id  = module.network.subnet-public-a_id
  subnet-public-b_id  = module.network.subnet-public-b_id
}

### Dynamic resources

module "repo_app" {
  source = "./modules/registry"
  
  project  = var.project
  env      = var.env
  app_name = "app"
}

module "app" {
  source = "./modules/application"

  project              = var.project
  env                  = var.env
  base_ami_id          = var.base_ami_id
  key_name             = var.key_name
  vpc_id               = module.network.vpc_id
  subnet-private-a_id  = module.network.subnet-private-a_id
  subnet-private-b_id  = module.network.subnet-private-b_id
  sg-bastion_id        = module.bastion.sg-bastion_id
  sg-alb_id            = module.loadbalancer.sg-alb_id
  alb-listener_arn     = module.loadbalancer.alb-listener-http_arn

  app_name          = "app"
  app_port          = 3000
  app_path          = "/"
  app_instance_type = "t3-small"
  app_storage_size  = 10
  app_min_size      = 1
  app_max_size      = 3
  app_desired_size  = 1
}
