# delete additional-scrape-configs secret firstly

```bash
kubectl -n kylincloud-monitoring-system delete secret additional-scrape-configs
```

# create additional-scrape-configs secret from prometheus file

```bash
kubectl -n kylincloud-monitoring-system create secret generic additional-scrape-configs --from-file=prometheus-additional.yaml
```

# The secrets should be modified both in two places:

1. roles/ky-istio/files/prometheus/prometheus-additional.yaml

2. keep roles/ky-monitor/files/prometheus/prometheus/additional-scrape-configs.yaml

`kubectl get secrets additional-scrape-configs -n kylincloud-monitoring-system`
