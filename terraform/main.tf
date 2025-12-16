terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "gd-gcp-internship-devops-tfstate"
    prefix = "terraform/state/petclinic"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Import modules
module "network" {
  source = "../../modules/network"
  
  project_id = var.project_id
  region     = var.region
  network    = var.network
  subnet     = var.subnet
}

module "database" {
  source = "../../modules/database"
  
  project_id          = var.project_id
  region              = var.region
  network_id          = module.network.vpc_id
  db_name             = "petclinic-db"
  db_user             = var.postgres_user
  db_password         = var.postgres_password
  db_database         = var.postgres_db
}

module "compute" {
  source = "../../modules/compute"
  
  project_id     = var.project_id
  region         = var.region
  zone           = var.zone
  network        = var.network
  subnet         = var.subnet
  vm_name        = var.vm
  external_ip    = var.ip
  service_account_email = var.service_account
}

module "storage" {
  source = "../../modules/storage"
  
  project_id = var.project_id
  region     = var.region
  repo_name  = var.repo
}

# Outputs
output "application_url" {
  value = "http://${module.compute.vm_external_ip}:${var.port}"
}

output "database_connection" {
  value = module.database.connection_name
  sensitive = true
}

output "artifact_registry_url" {
  value = module.storage.artifact_registry_url
}
