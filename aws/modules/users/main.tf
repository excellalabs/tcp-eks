resource "aws_iam_user" "eks_deployer" {
  name = "eks_deployer"
  path = "/eks/"
}

# The most important part is the iam:PassRole. With that, this user can give roles to container tasks.
# In theory the user can give the task Admin rights. To make sure that does not happen we restrict
# the user and allow him only to hand out roles in /eks/ path. You still need to be careful not
# to have any roles in there with full admin rights, but no container task should have these rights!
resource "aws_iam_user_policy" "eks_deployer_policy" {
  name = "eks_deployer_policy"
  user = "${aws_iam_user.eks_deployer.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:RegisterTaskDefinition",
                "eks:DescribeTaskDefinition",
                "eks:ListTaskDefinitions",
                "eks:CreateService",
                "eks:UpdateService",
                "eks:DescribeServices",
                "eks:ListServices"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": ["iam:PassRole"],
            "Resource": "arn:aws:iam::*:role/eks/*"
        }
    ]
}
EOF
}

resource "aws_iam_access_key" "eks_deployer" {
  user = "${aws_iam_user.eks_deployer.name}"
}
