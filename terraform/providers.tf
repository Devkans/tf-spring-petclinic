terraform {
  backend "gcs" {
    bucket = "spring-petclinic-tf-state"
    prefix = "infra"
  }
}

