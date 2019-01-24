resource "google_container_cluster" "gke-cluster" {
  name               = "${var.project}-${var.environment}-cluster"
  network            = "${var.network}"
  zone               = "${var.zone}"
  initial_node_count = "${var.node_count}"
}