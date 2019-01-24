terraform {
  backend "gcs" {
    bucket      = "gke-tf-bench-tfstate"
    credentials = "./creds/service_account.json"
  }
}