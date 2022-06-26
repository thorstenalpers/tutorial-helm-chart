
# Create a .Net5 project and deploy it as helm chart

This is a step by step tutorial to create a .Net5 WebApi project and at the end deploy it to local kubernetes cluster and debug with VisualStudio.

A much simpler but smaller example can be found [here](A simple helm chart for an asp application 
https://github.com/Crokus/aspnet-core-helm-sample/tree/master/chart).

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

2. Change the docker repository and tag in values.yaml

```
image:
  repository: my-project
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: "latest"
```


3. Set the correct health check pathes in deployment.yaml or remove them

```
          livenessProbe:
            httpGet:
              path: /health/live
              port: http
          readinessProbe:
            httpGet:
              path: /health/ready
              port: http
```

4. Install the chart

```
helm install my-example ./src/charts/my-example
```


5. Create a nodeport service to expose the service port permanently

5.1. Create a new file "service-nodeport.yaml" containing a configuration of a nodeport service 
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

5.2. Publish nodeport service into local kubernetes cluster

```
kubectl apply -f ./service-nodeport.yaml
```

6. Test the application. Open the browser http://localhost:30031/swagger

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


