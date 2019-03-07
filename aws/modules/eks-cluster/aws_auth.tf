resource "local_file" "config_map_aws_auth" {
  content  = "${data.template_file.config_map_aws_auth.rendered}"
  filename = "${var.config_output_path}aws_auth_configmap.yaml"
  count    = "${var.write_aws_auth_config ? 1 : 0}"
}

resource "null_resource" "update_config_map_aws_auth" {
  depends_on = ["aws_eks_cluster.cluster"]

  provisioner "local-exec" {
    command = <<EOS
for i in `seq 1 10`; do \
kubectl apply -f ${local_file.config_map_aws_auth.filename} \
--kubeconfig ${local_file.kubeconfig.filename} && break || sleep 10; \
done;
EOS
  }
  triggers {
    config_map_rendered = "${data.template_file.config_map_aws_auth.rendered}"
  }
  count = "${var.write_aws_auth_config ? 1 : 0}"
}