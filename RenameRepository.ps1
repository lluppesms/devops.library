az acr repository show --name lllbicepregistry --repository bicep/cosmosdatabase
az acr repository update -n lllbicepregistry --image bicep/cosmosdatabase:2022-08-24.256 --write-enabled false
az acr repository untag -n lllbicepregistry --image bicep/cosmosdatabase:2022-08-24.256 

az acr import --name lllbicepregistry --source lllbicepregistry.azurecr.io/bicep/cosmosdatabase:2022-08-24.256 --image bicep/cosmosdatabase:latest --force
