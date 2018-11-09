data "template_file" "chef" {
  template = "${file("${path.module}/templates/chef.json")}"

  vars = {
    aws_access_key_id              = "${var.aws_access_key}"
    aws_secret_access_key          = "${var.aws_secret_key}"
    aws_region                     = "${data.aws_region.current.name}"
    jenkins_email                  = "${var.aws_email}"
    jenkins_github_ci_user         = "${var.jenkins_github_ci_user}"
    jenkins_github_ci_token        = "${var.jenkins_github_ci_token}"
    jenkins_developer_password     = "${var.jenkins_developer_password}"
    jenkins_admin_password         = "${var.jenkins_admin_password}"
    jenkins_seedjob_branch_include = "${var.jenkins_seedjob_branch_include}"
    jenkins_seedjob_branch_exclude = "${var.jenkins_seedjob_branch_exclude}"
    jenkins_seedjob_branch_trigger = "${var.jenkins_seedjob_branch_trigger}"
    jenkins_seedjob_repo_include   = "${var.jenkins_seedjob_repo_include}"
    jenkins_seedjob_repo_exclude   = "${var.jenkins_seedjob_repo_exclude}"
    jenkins_seedjob_repo_owner     = "${var.jenkins_seedjob_repo_owner}"
  }
}

# Package the cookbooks into a single file for easy uploading
# gem install --user-install berkshelf
resource "null_resource" "berks_package" {
  # asuming this is run from a cookbook/terraform directory
  provisioner "local-exec" {
    command = "rm -f ${path.module}/cookbooks.tar.gz ; berks package ${path.module}/cookbooks.tar.gz --berksfile=${path.module}/cookbooks/demo/Berksfile"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.jenkins_key_name}"
  public_key = "${file(var.jenkins_public_key_path)}"
}

resource "aws_instance" "jenkins_master" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "${var.jenkins_instance_type}"
  associate_public_ip_address = "${var.jenkins_associate_public_ip_address}"
  subnet_id                   = "${module.public_subnet.ids[0]}"
  vpc_security_group_ids      = ["${aws_security_group.jenkins_sg.id}"]
  key_name                    = "${aws_key_pair.auth.key_name}"

  root_block_device = {
    volume_type = "${var.jenkins_root_volume_type}"
    volume_size = "${var.jenkins_root_volume_size}"
    delete_on_termination = "${var.jenkins_root_volume_delete_on_termination}"
  }

  tags {
    Name        = "jenkins_master"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }

  connection {
    user        = "ubuntu"
    private_key = "${file(var.jenkins_private_key_path)}"
  }

  provisioner "file" {
    source      = "${path.module}/cookbooks.tar.gz"
    destination = "/tmp/cookbooks.tar.gz"
  }

  provisioner "file" {
    content     = "${data.template_file.chef.rendered}"
    destination = "/tmp/chef.json"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -LO https://www.chef.io/chef/install.sh && sudo bash ./install.sh",
      "sudo chef-solo --recipe-url /tmp/cookbooks.tar.gz -j /tmp/chef.json",
    ]
  }

  depends_on = ["null_resource.berks_package"]
}
