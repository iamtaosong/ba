defaultAdmissionRule:
  enforcementMode: ${default_enforcementMode}
  evaluationMode: ${default_evaluationMode}
  requireAttestationsBy:
  - projects/${project_id}/attestors/${default_attestor}
globalPolicyEvaluationMode: ${globalPolicyEvaluationMode}
kubernetesNamespaceAdmissionRules:
  kubeflow:
    enforcementMode: ${ns_kf_enforcementMode}
    evaluationMode: ${ns_kf_evaluationMode}
    requireAttestationsBy:
    - projects/${project_id}/attestors/${kubeflow_attestor}
