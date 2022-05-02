resource "google_binary_authorization_attestor" "kubeflow-namespace-attestor" {
  name = "gke-ns-kubflow-attestor"
  attestation_authority_note {
    note_reference = google_container_analysis_note.note.name
    public_keys {
      id = data.google_kms_crypto_key_version.version.id
      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.version.public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.version.public_key[0].algorithm
      }
    }
  }
}


resource "null_resource" "this" {
  triggers = {
    template = "${data.template_file.ba-policy.rendered}"
  }
  provisioner "local-exec" {
    command = <<-EOT
      tmp_d=$(mktemp -d)
      tmp_f="$tmp_d/binary-authz-policy.yaml"
       gcloud config set project ${var.project_id}
      echo "${data.template_file.ba-policy.rendered}" > $tmp_f
      gcloud container binauthz policy import $tmp_f
      echo  "$tmp_d"
    EOT
  }
}

data "template_file" "ba-policy" {
  template = "${file("./binary-authz-policy.tpl")}"
  vars = {
    default_enforcementMode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    default_evaluationMode  = "REQUIRE_ATTESTATION"
    globalPolicyEvaluationMode  = "DISABLE"   
    ns_kf_enforcementMode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    ns_kf_evaluationMode = "REQUIRE_ATTESTATION"
    default_attestor  = google_binary_authorization_attestor.attestor.name
    kubeflow_attestor = google_binary_authorization_attestor.kubeflow-namespace-attestor.name
    project_id        = var.project_id
  }
}