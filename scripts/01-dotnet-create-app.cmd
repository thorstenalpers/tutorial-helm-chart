REM Creates a sample project
dotnet new webapi -n Examples.HelmChart -o ..\src
dotnet new sln -n Examples.HelmChart -o ..\
dotnet sln ..\Examples.HelmChart.sln add ..\src

set /p DUMMY=Hit ENTER to continue...