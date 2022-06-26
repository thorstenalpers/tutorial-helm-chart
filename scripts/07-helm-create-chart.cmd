REM Create a helm chart in subfolder charts 
cd ..\src 
mkdir charts
cd charts
helm create my-example  

set /p DUMMY=Hit ENTER to continue...