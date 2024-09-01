helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm search repo prometheus-community

helm install prometheus prometheus-community/kube-prometheus-stack \
--version "62.3.1" \ 
--namespace monitoring \ 
--create-namespace