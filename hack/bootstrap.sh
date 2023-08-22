# This file is to bootstrap the initial management GKE cluster which will be called cluster-00.
# Additionally it will setup tooling such as SOPS GCP KMS encryption.
# https://cloud.google.com/config-connector/docs/how-to/advanced-install
# https://github.com/getsops/sops#23encrypting-using-gcp-kms
# https://fluxcd.io/flux/guides/mozilla-sops/#google-cloud

export PROJECT_ID=anz-next-demo-23
export CLUSTER_NAME=cluster-00
export CLUSTER_REGION=us-west1

# export GITHUB_TOKEN=<>

export KCC_SERVICE_ACCOUNT_NAME=kcc-sa
export SOPS_SERVICE_ACCOUNT_NAME=sops-sa

# gcloud auth login
# gcloud auth application-default login
# gcloud config set project $PROJECT_ID

gcloud services enable \
  servicemanagement.googleapis.com \
  servicecontrol.googleapis.com \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudkms.googleapis.com \
  gkeconnect.googleapis.com \
  gkehub.googleapis.com \
  iam.googleapis.com \
  mesh.googleapis.com \
  multiclusterservicediscovery.googleapis.com \
  multiclusteringress.googleapis.com \
  trafficdirector.googleapis.com \
  anthos.googleapis.com \
  dns.googleapis.com

# Setup a KCC service account with appropriate permissions.
gcloud iam service-accounts create ${KCC_SERVICE_ACCOUNT_NAME}

# TODO: This is not the best practice, but for the sake of the demo, we will give the service account owner access.
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${KCC_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/owner"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${KCC_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud iam service-accounts add-iam-policy-binding \
  ${KCC_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
  --role="roles/iam.workloadIdentityUser"

# Setup a SOPS service account with appropriate permissions. This is used for encrypting secrets.
gcloud iam service-accounts create ${SOPS_SERVICE_ACCOUNT_NAME}

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SOPS_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SOPS_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

gcloud iam service-accounts add-iam-policy-binding \
 ${SOPS_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[flux-system/kustomize-controller]" \
  --role="roles/iam.workloadIdentityUser"

gcloud kms keyrings create sops --location global
gcloud kms keys create sops-key --location global --keyring sops --purpose encryption
gcloud kms keys list --location global --keyring sops

# Setup the Management GKE cluster
gcloud container clusters create-auto $CLUSTER_NAME \
    --region $CLUSTER_REGION \
    --project $PROJECT_ID \
    --release-channel rapid

gcloud container clusters get-credentials $CLUSTER_NAME \
    --region $CLUSTER_REGION \
    --project $PROJECT_ID

# Add a one-time Github token to the cluster
kubectl create secret generic github-token \
  --namespace=flux-system \
  --from-literal=token=$GITHUB_TOKEN \
  --dry-run=client -oyaml \
  > kubernetes/namespaces/base/flux-system/addons/notifications/github/secret.enc.yaml

sops --encrypt --in-place kubernetes/namespaces/base/flux-system/addons/notifications/github/secret.enc.yaml

# Bootstrap FluxCD
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner="xUnholy" \
  --repository="next-demo-01" \
  --path=kubernetes/clusters/$CLUSTER_NAME \
  --branch="main" \
  --personal=true \
  --private=false

# Create Service Endpoint
# TODO

# Create public IP for XLB
gcloud compute addresses create static-mci-ip --global
gcloud compute addresses list

# Create Certificate
# TODO

# Create Ingress Objects
# TODO

# Step 3 -> https://cloud.google.com/kubernetes-engine/docs/how-to/multi-cluster-services
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$PROJECT_ID.svc.id.goog[gke-mcs/gke-mcs-importer]" \
    --role "roles/compute.networkViewer"
