# prometheus (helm-provider)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm search repo prometheus-community

helm install prometheus prometheus-community/kube-prometheus-stack \
    --version "62.3.1" \
    --namespace monitoring \
    --create-namespace

# prometheus-adapter (helm-provider)
helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter \
    -f ./adapter/values.yaml

# argocd (helm-provider)
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd
helm install argocd argo/argo-cd --namespace argocd

# this will be later migrated to a controller
helm install my-infra application-infrastructure/

# environments: apps, ingress, networking policies (kubectl-provider)
kubectl apply -f .init/