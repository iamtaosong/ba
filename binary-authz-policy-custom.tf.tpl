defaultAdmissionRule:
  enforcementMode: ${default_enforcementMode}
  evaluationMode: ${default_evaluationMode}
  requireAttestationsBy:
  - ${default_attestor}
globalPolicyEvaluationMode: ${globalPolicyEvaluationMode}
kubernetesNamespaceAdmissionRules:
  kubeflow:
    enforcementMode: ${ns_kf_enforcementMode}
    evaluationMode: ${ns_kf_evaluationMode}
    requireAttestationsBy:
    - ${kubeflow_attestor}
    
    
resource "google_binary_authorization_policy" "this" {
  count = var.ns_ba_policy == true ? 0 : 1
  project = var.project_id
  dynamic "admission_whitelist_patterns" {
    for_each = var.admission_whitelist_patterns
    content {
      name_pattern = admission_whitelist_patterns.value
    }
  }
  default_admission_rule {
    evaluation_mode  = var.evaluation_mode
    enforcement_mode = var.enforcement_mode
  }
  global_policy_evaluation_mode = var.global_policy_evaluation_mode
}

resource "null_resource" "this" {
  count = var.ns_ba_policy == true ? 1 : 0
  triggers = {
    template = "${data.template_file.ba-policy[0].rendered}"
  }
  provisioner "local-exec" {
    command = <<-EOT
      tmp_d=$(mktemp -d)
      tmp_f="$tmp_d/binary-authz-policy.yaml"
      gcloud config set project ${var.project_id}
      echo "${data.template_file.ba-policy[0].rendered}" > $tmp_f
      gcloud container binauthz policy import $tmp_f
      echo  "$tmp_d"
    EOT
  }
}



data "template_file" "ba-policy" {
  count    = var.ns_ba_policy == true ? 1 : 0
  template = "${file("${path.module}/binary-authz-policy.tpl")}"
  vars = {
    default_enforcementMode    =  var.enforcement_mode //"ENFORCED_BLOCK_AND_AUDIT_LOG"
    default_evaluationMode     =  "REQUIRE_ATTESTATION"
    globalPolicyEvaluationMode =  var.global_policy_evaluation_mode
    ns_kf_enforcementMode      = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    ns_kf_evaluationMode       = "REQUIRE_ATTESTATION"
    default_attestor           = var.default_attestor_id
    kubeflow_attestor          = var.kubeflow_attestor_id
  }
}


variable "admission_whitelist_patterns" {
  type    = list
  default = []
}

variable "enforcement_mode" {
  type        = string
  description = "svc hub  project ID"
  default     = "DRYRUN_AUDIT_LOG_ONLY"
}

variable "evaluation_mode" {
  type        = string
  description = "svc hub  project ID"
  default     = "ALWAYS_DENY"
}

variable "global_policy_evaluation_mode" {
  type        = string
  description = "svc hub  project ID"
  default     = "DISABLE"
}

variable "ns_ba_policy" {
  type    = bool
  default = false
}

variable "default_attestor_id" {
  type    = string
  default = ""
}
variable "kubeflow_attestor_id" {
  type    = string
  default = ""
}

variable "project_id" {
  type    = string
}





# module "exp_binary_auth_policy" {
#   source     = "./module/ba-policy"
#   project_id = var.project_id
#   # admission_whitelist_patterns = ["gcr.io/google_containers/", "gcr.io/google_containers/tao"]
# }


module "pr_binary_auth_policy" {
  source     = "./module/ba-policy"
  project_id = var.project_id
  # admission_whitelist_patterns = ["gcr.io/google_containers/", "gcr.io/google_containers/tao"]
  ns_ba_policy         = true
  default_attestor_id  = module.kubeflow_namespace_attestor.attestor_id
  kubeflow_attestor_id = module.kubeflow_namespace_attestor.attestor_id
}
