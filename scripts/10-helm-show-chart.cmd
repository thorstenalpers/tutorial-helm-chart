REM Test that chart works as expected
helm show values ../src/charts/my-example > my-example-values.yaml

helm template ../src/charts/my-example > my-example-template.yaml

set /p DUMMY=Hit ENTER to continue...