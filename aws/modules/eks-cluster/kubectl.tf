resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "${var.config_output_path}kubeconfig.yaml"
  count    = "${var.write_kubeconfig ? 1 : 0}"
}