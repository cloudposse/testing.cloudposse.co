availability_zones = ["us-west-2a", "us-west-2b"]

vpc_cidr_block = "172.16.0.0/16"

name = "eks-test"

instance_types = ["t3.small"]

desired_size = 2

max_size = 3

min_size = 2

disk_size = 30

kubeconfig_path = "/.kube/config"

kubernetes_labels = {}

chamber_service = "eks"

cluster_kubernetes_version = "1.14"

nodes_kubernetes_version = "1.14"
