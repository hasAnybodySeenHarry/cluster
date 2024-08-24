helm uninstall my-infra
helm uninstall expenses
helm uninstall notifier
helm uninstall throttler

helm install my-infra application-infrastructure/
helm install expenses expenses/
helm install notifier notifier/
helm install throttler throttler/