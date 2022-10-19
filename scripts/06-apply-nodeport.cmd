REM kubectl port-forward svc/my-example 30031:80
kubectl apply -f ./service-nodeport.yaml

set /p DUMMY=Hit ENTER to continue...