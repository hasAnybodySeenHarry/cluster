# argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd
helm install argocd argo/argo-cd --namespace argocd

# this will be later migrated to a controller
helm install my-infra application-infrastructure/

# environments (apps, ingress, networking rules)
kubectl apply -f .init/