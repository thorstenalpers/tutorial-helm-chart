
# Create a .Net5 project and deploy it as helm chart

This is a step by step tutorial to create a .Net5 WebApi project and at the end deploy it to a local kubernetes cluster and debug it with VisualStudio.


## Create a .Net5 project

1. Create a project and solution

```powershell
dotnet new webapi -n Examples.HelmChart -o .\src
dotnet new sln -n Examples.HelmChart -o .\
dotnet sln Examples.HelmChart.sln add .\src
```

2. Remove Https redirection in startup.cs

```csharp
// app.UseHttpsRedirection();
```

3. (Optional) Add HealthChecks, see [Microsoft Docs](https://docs.microsoft.com/de-de/aspnet/core/host-and-deploy/health-checks?view=aspnetcore-5.0)

4. Run project locally with VS2019 on IIS and make sure application is running


## Pack application into a docker image

1. Add two Dockerfiles

1.1. Create a file named Dockerfile
```
FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
COPY ["Examples.HelmChart.csproj", "./"]

RUN dotnet restore "./Examples.HelmChart.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "Examples.HelmChart.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Examples.HelmChart.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Examples.HelmChart.dll"]
```

```
2. Add docker configuration to launchSettings.json

```json
{
  "$schema": "http://json.schemastore.org/launchsettings.json",
  "profiles": {
    "Local": {
      "commandName": "Project",
      "launchBrowser": true,
      "launchUrl": "swagger",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      },
      "dotnetRunMessages": "true",
      "applicationUrl": "http://localhost:5000"
    },
    "Docker": {
      "commandName": "Docker",
      "launchBrowser": true,
      "launchUrl": "{Scheme}://{ServiceHost}:{ServicePort}/swagger",
      "publishAllPorts": true
    },
    "Bridge to Kubernetes": {
      "commandName": "AzureDevSpacesLocal",
      "launchBrowser": true
    }
  }
}
```

3. Run project locally with VS2019 on Docker and make sure application is running

4. Build docker file so that a docker images is created, with docker images can you list the local docker images

```
docker build -t my-example:latest .\
```

5. Test deploymnet of container

```powershell
docker run -it --rm -e "ASPNETCORE_ENVIRONMENT=Development" --name my-example -p 8080:80 my-example:latest 
```

and open the browser with url http://localhost:8080/swagger


### Additional Links

Reference of docker commands

* https://docs.docker.com/engine/reference/run/

## Pack application into a helm chart

1. Create a helm chart

```
mkdir charts
cd charts
helm create my-example  
```

2. Modify helm chart

2.1. Change the docker repository and tag in values.yaml

```
image:
  repository: my-example
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: "latest"
```

And also the ingress (forwarding rules) settings
```
ingress:
  enabled: true
  # className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: my-example.localhost
      paths:
        - path: /
          pathType: Prefix
  tls: []
   # - secretName: localhost-secret
     # hosts:
       # - localhost
```   

2.2.
Change health check urls or remove them

```

          livenessProbe:
            httpGet:
              path: /swagger
              port: http
          readinessProbe:
            httpGet:
              path: /swagger
              port: http
```
3. Install the chart

```
helm install my-example ./src/charts/my-example
```


4. Make application visible from outside the cluster

Either expose a port or create an ingress which makes your application reachable via Https

4.1.1. Create a nodeport service to expose the service port permanently

4.1.2. Create a new file "service-nodeport.yaml" containing a configuration of a nodeport service 
```
apiVersion: v1
kind: Service
metadata:
  name: my-example-nodeport
spec:
  type: NodePort
  selector:
    app.kubernetes.io/instance: my-example # label of the pod
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30031
```

4.1.3. Publish nodeport service into local kubernetes cluster

```
kubectl apply -f ./service-nodeport.yaml
```

An alternative would be to move this yaml file into the helm/templates folder of the chart and install it with helm


4.1.4. Test the application. Open the browser http://localhost:30031/swagger


5. Make your application reachable via Https

5.1.
Change values yaml 
```
ingress:
  enabled: true
  className: "nginx"
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: my-example.localhost
      paths:
        - path: /
          pathType: Prefix
  tls: 
    - secretName: localhost-secret
      hosts:
        - localhost
```

5.2.
Create a file with name cert.conf
```
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = US
ST = VA
L = SomeCity
O = MyCompany
OU = MyDivision
CN = localhost
[v3_req]
keyUsage = critical, digitalSignature, keyAgreement
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = my-example.localhost
```


5.3.
Install and Configure nginx so that the ssl certificate will be used
 
Get values of nginx deployment
 ```
  helm show values ingress-nginx/ingress-nginx > nginx-values.yaml
```

Add the ssl certificate to  the values of nginx deployment
```
  extraArgs:
    default-ssl-certificate: "default/localhost-secret"
```

Install nginx
 ```
helm install ingress-nginx ingress-nginx/ingress-nginx -f nginx-values.yaml 
```

5.4.

Install SSL certificate on your server.

5.4.1. Double click on server.crt
5.4.1. Install cert ...
5.4.1. Current User
5.4.1. Place all certificates in the following store
5.4.1. Trusted Root Certification Authorities


5.5. Test the application. 
Open the browser http://localhost:30031/swagger
Open the browser https://my-example.localhost/swagger

### Additional Links

Reference of helm commands
* https://helm.sh/docs/helm/helm/

Detailled Explanation of all files and fields of a helm chart
* https://helm.sh/docs/topics/charts/

Naming Convention for Helm Charts
https://helm.sh/docs/chart_best_practices/conventions/

## Debug application with Bridge to Kubernetes


1. Add some breakpoints in the controller actions

2. Run Bridge to Kubernetes and enter as apllication url http://localhost:30031/swagger

3. Execute some API actions from within SwaggerUI

### Additional Links

Bridge to Kubernetes
* https://docs.microsoft.com/de-de/visualstudio/containers/overview-bridge-to-kubernetes?view=vs-2019


