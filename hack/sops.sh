PROJECT_ID=kubecon-mgmt
CLUSTER_NAME=cluster-00
SERVICE_ACCOUNT_NAME=sops-sa

gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME}

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud iam service-accounts add-iam-policy-binding \
 ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[flux-system/kustomize-controller]" \
  --role="roles/iam.workloadIdentityUser"
