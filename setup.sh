helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

kubectl create namespace argocd

helm install argocd argo/argo-cd --namespace argocd

kubectl apply -f argo/ingress-nginx.yaml

helm uninstall my-infra
helm uninstall expenses
helm uninstall notifier
helm uninstall throttler

helm install my-infra application-infrastructure/
helm install expenses expenses/
helm install notifier notifier/
helm install throttler throttler/

kubectl apply -f ingress.yaml