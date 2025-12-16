terraform {
  backend "gcs" {
    bucket = "spring-petclinic-tfe-ar"  
    prefix = "terraform/state"         
  }
}
