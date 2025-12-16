resource "google_sql_database_instance" "postgres" {
  name             = var.db_name
  database_version = "POSTGRES_15"
  region           = var.region
  
  settings {
    tier = "db-f1-micro"
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
    }
    
    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = false # Set to true for production
}

resource "google_sql_database" "database" {
  name     = var.db_database
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}

output "connection_name" {
  value = google_sql_database_instance.postgres.connection_name
}

output "private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}
