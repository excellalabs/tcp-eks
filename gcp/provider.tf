provider "google" {
  credentials = "${file("./creds/${var.service_account}")}"
  project     = "${var.project}"
  region      = "${var.region}"
}