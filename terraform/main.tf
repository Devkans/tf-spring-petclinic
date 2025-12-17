terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "spring-petclinic-tfe-ar"
    prefix = "terraform/state"
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

resource "google_compute_firewall" "allow_app" {
  name    = "${var.network}-allow-app"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]  # SSH + Application
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["petclinic-vm"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["petclinic-vm"]
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
    
    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = false  # Set to true for production
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

  tags = ["petclinic-vm"]

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
    # Install Docker
    apt-get update
    apt-get install -y docker.io docker-compose
    systemctl start docker
    systemctl enable docker
    usermod -aG docker $(whoami)
    
    # Create app directory
    mkdir -p /opt/petclinic
    
    # Create .env file for database connection
    cat > /opt/petclinic/.env << 'ENV_EOF'
    POSTGRES_URL=jdbc:postgresql://${google_sql_database_instance.postgres.private_ip_address}:5432/${var.postgres_db}
    POSTGRES_USER=${var.postgres_user}
    POSTGRES_PASSWORD=${var.postgres_password}
    ENV_EOF
  EOF
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.repo
  format        = "DOCKER"
  
  docker_config {
    immutable_tags = false
  }
}
resource "google_storage_bucket" "petclinic_logs" {
  name          = "petclinic-logs-${var.project_id}"
  location      = var.region
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = "dev"
    purpose     = "logs"
    terraform   = "true"
  }
}

output "application_url" {
  value = "http://${google_compute_address.static_ip.address}:${var.port}"
}

output "database_private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}

output "vm_external_ip" {
  value = google_compute_address.static_ip.address
}

output "artifact_registry_url" {
  value = google_artifact_registry_repository.repo.name
}

output "log_bucket_url" {
  value = google_storage_bucket.petclinic_logs.url
}
