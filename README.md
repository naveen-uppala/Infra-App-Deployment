###  helm Installation steps:
```
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```
```
helm version | cut -d + -f 1
```
###  helm Deployment steps:
```
helm create helmchartname
```
```
tree helmchartname
```

or 

```
use ls 
```
```
helm template helmchartname
```
```
helm lint <chart_directory>
```
###### List releases
```
helm list [flags]
```
###### Uninstall a Helm release from Kubernetes.
```
helm uninstall <release_name>
```
###### Install a Helm chart onto Kubernetes.
```
helm install <release_name> <chart_name> [flags]
```
###### Rollback to a previous version of a release
```
helm rollback release_name revsion_number chart_name
```
###### Upgrade a Helm release to a new version or configuration
```
helm upgrade <release_name> <chart_name> [flags]
```
##### upgrade or install a Helm release with a specified chart and set a specific image tag
```
helm upgrade release_name --install chart_name --set image.tag=tag_name
```
 ###### Show information about a chart.
```
helm show chart <chart_name>
helm show values <chart_name>

```
