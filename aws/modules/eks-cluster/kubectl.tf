resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "${var.config_output_path}kubeconfig-${var.cluster_name}"
  count    = "${var.write_kubeconfig ? 1 : 0}"
}