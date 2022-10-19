REM Executes an image in a container and exposes internal port 80 to 8080, http://localhost:8080/swagger

docker run -it --rm -e "ASPNETCORE_ENVIRONMENT=Development" --name my-example -p 8080:80 my-example:latest 

"C:\Program Files\Mozilla Firefox\firefox.exe" -new-tab "http://localhost:8080/swagger"

REM -it =    interactive + tty
REM --rm =   Automatically remove the container when it exits
REM -e =     Set environment variables
REM --name = Give docker container a name, default is a random name
REM -p =     Publish port

set /p DUMMY=Hit ENTER to continue...