
## 1. argocd password check 
``` bash
k get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
```

## 2. port forwarding
``` bash
k port-forward svc/argocd-server -n argocd 8080:443
```


## if some problem occur
``` bash
kubectl delete apiservice v1.metrics.eks.amazonaws.com

kubectl rollout restart statefulset argocd-application-controller -n argocd
```