resource "local_file" "config_map_aws_auth" {
  content  = "${data.template_file.config_map_aws_auth.rendered}"
  filename = "${var.config_output_path}aws_auth_configmap.yaml"
  count    = "${var.write_aws_auth_config ? 1 : 0}"
}

resource "null_resource" "update_config_map_aws_auth" {
  depends_on = ["aws_eks_cluster.cluster"]

  provisioner "local-exec" {
    command = "import subprocess, time; for i in range(5): time.sleep(10); if subprocess.check_call('kubectl apply -f ${local_file.config_map_aws_auth.filename} --kubeconfig ${local_file.kubeconfig.filename}') == 0: break"
    working_dir = "${var.config_output_path}"
    interpreter = ["python", "-c"]
  }
  triggers {
    config_map_rendered = "${data.template_file.config_map_aws_auth.rendered}"
  }
  count = "${var.write_aws_auth_config ? 1 : 0}"
}