# generate mTLS certificates
# ...

# install linkerd (helm-provider)
helm repo add linkerd-edge https://helm.linkerd.io/edge
helm repo update linkerd-edge
helm install linkerd-crds linkerd-edge/linkerd-crds \
  --namespace linkerd \
  --create-namespace
helm install linkerd-control-plane linkerd-edge/linkerd-control-plane \
  --namespace linkerd \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \

# install prometheus (helm-provider)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm install prometheus prometheus-community/kube-prometheus-stack \
    --version "62.3.1" \
    --namespace monitoring \
    --create-namespace \
    --set prometheus.prometheusSpec.podMetadata.annotations."linkerd\.io/inject"=enabled

# install prometheus-adapter (helm-provider)
helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter \
    -f ./prom-adapter/values.yaml \
    --namespace monitoring

# install argocd (helm-provider)
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd
helm install argocd argo/argo-cd --namespace argocd

# this will be later migrated to independent managed services
helm install my-infra application-infrastructure/

# create ArgoCD env apps, repositories, and ingress (kubectl-provider)
kubectl apply -f .init/

# check out mesh layer repository and install mesh (git and helm providers)