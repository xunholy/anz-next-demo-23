# This file is to bootstrap the SOPs GCP KMS encryption.
# This using the following documentation https://github.com/getsops/sops#23encrypting-using-gcp-kms
# Additional documentation https://fluxcd.io/flux/guides/mozilla-sops/#google-cloud

PROJECT_ID=kubecon-mgmt
CLUSTER_NAME=cluster-00
SERVICE_ACCOUNT_NAME=sops-sa

gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME}

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

gcloud iam service-accounts add-iam-policy-binding \
 ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[flux-system/kustomize-controller]" \
  --role="roles/iam.workloadIdentityUser"



gcloud kms keyrings create sops --location global
gcloud kms keys create sops-key --location global --keyring sops --purpose encryption
gcloud kms keys list --location global --keyring sops
