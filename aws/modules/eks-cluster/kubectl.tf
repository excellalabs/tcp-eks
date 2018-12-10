resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "${path.module}/files/kubeconfig-${var.cluster_name}"
  count    = "${var.write_kubeconfig ? 1 : 0}"
}