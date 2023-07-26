# This file is to bootstrap the initial management GKE cluster which will be called cluster-00.
# This using the following documentation https://cloud.google.com/config-connector/docs/how-to/advanced-install

PROJECT_ID=kubecon-mgmt
CLUSTER_NAME=cluster-00
SERVICE_ACCOUNT_NAME=kcc-sa

gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME}

# TODO: This is not the best practice, but for the sake of the demo, we will give the service account owner access.
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/owner"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud iam service-accounts add-iam-policy-binding \
  ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
  --role="roles/iam.workloadIdentityUser"
