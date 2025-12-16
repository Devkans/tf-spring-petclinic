terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "spring-petclinic-tf-state"
    prefix = "infra"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc" {
  name                    = var.network
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow_ssh_http" {
  name    = "petclinic-fw"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_sql_database_instance" "postgres" {
  name             = "petclinic-db"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "database" {
  name     = var.postgres_db
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "user" {
  name     = var.postgres_user
  instance = google_sql_database_instance.postgres.name
  password = var.postgres_password
}

resource "google_compute_address" "static_ip" {
  name = var.ip
}

resource "google_compute_instance" "vm" {
  name         = var.vm
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["petclinic-vm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  service_account {
    email  = "terraform-ci@gd-gcp-internship-devops.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io docker-compose
    systemctl start docker
    systemctl enable docker
    usermod -aG docker $(whoami)
    mkdir -p /opt/petclinic
  EOF
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.repo
  format        = "DOCKER"
}

output "application_url" {
  value = "http://${google_compute_address.static_ip.address}:${var.port}"
}

output "database_private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}




