# module "platform" {
#   source  = "app.terraform.io/harryyan/eks-platform/aws"
#   version = "1.0.4"

#   project_name = "flextrack"
#   department   = "QA"
#   environment  = "staging"

#   eks_version  = "1.31"

#   eks_params = {
#     cluster_endpoint_public_access = true
#     cluster_enabled_log_types      = ["audit", "api", "authenticator"]
#   }

#   eks_managed_node_group_params = {
#     default_group = {
#       min_size       = 1
#       max_size       = 2
#       desired_size   = 1
#       instance_types = ["t2.medium"]
#       capacity_type  = "ON_DEMAND"
#       taints = [
#         {
#           key      = "CriticalAddonsOnly"
#           value    = "true"
#           operator = "Equal"
#           effect   = "NoSchedule"
#         },
#         {
#           key      = "CriticalAddonsOnly"
#           value    = "true"
#           operator = "Equal"
#           effect   = "NoExecute"
#         }
#       ]
#       max_unavailable_percentage = 50
#     }
#   }

#   karpenter_provisioner = [
#     {
#       name          = "default"
#       instance-type = ["t3.small", "t3.medium", "t3.large"]
#       topology      = ["us-east-1a", "us-east-1b"]
#       labels = {
#         created-by = "karpenter"
#       }
#     }
#   ]

#   eks_addons_version = {
#     coredns            = "v1.11.3-eksbuild.1"
#     kube_proxy         = "v1.31.0-eksbuild.2"
#     vpc_cni            = "v1.18.3-eksbuild.2"
#     aws_ebs_csi_driver = "v1.36.0-eksbuild.1"
#   }

#   helm_release_versions = {
#     karpenter                             = "1.0.8"
#     external_dns                          = "1.13.1"
#     aws_load_balancer_controller          = "1.10.0"
#     secrets_store_csi_driver              = "1.4.6"
#     secrets_store_csi_driver_provider_aws = "0.3.4"
#   }

#   external_dns_zone = "crunchy.uk.co"

#   argocd_env = [
#     {
#       app-name        = "dev-apps",
#       repository-url  = "https://github.com/hasAnybodySeenHarry/cluster"
#       target-revision = "HEAD"
#       source-path     = "develop"
#     },
#     {
#       app-name        = "prod-apps",
#       repository-url  = "https://github.com/hasAnybodySeenHarry/cluster"
#       target-revision = "HEAD"
#       source-path     = "production"
#     },
#     {
#       app-name        = "staging-apps",
#       repository-url  = "https://github.com/hasAnybodySeenHarry/cluster"
#       target-revision = "HEAD"
#       source-path     = "staging"
#     }
#   ]

#   prometheus_adapter_rules_filepath = "${path.module}/configs/prometheus-adapter.yaml"
# }

module "platform" {
  source  = "app.terraform.io/harryyan/pseudo/null"
  version = "1.0.2"
}