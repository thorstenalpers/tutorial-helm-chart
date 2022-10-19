
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx -f nginx-values.yaml 

set /p DUMMY=Hit ENTER to continue...