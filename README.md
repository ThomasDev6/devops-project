# Rendu : Deveci Serkan et Jallu Thomas
## Ecrivez ici les inscriptions et explications pour déployer l'infrastructure et l'application sur Azure

### Prérequis
#### Assurez-vous d'avoir les outils suivants :
- Terraform
- Azure CLI
- Docker
- Helm

### Etape 1 : Partie Terraform

- Entrer dans le dossier terraform

```bash
cd terraform
```
- Premièrement il faut se connecter à Azure

```bash
az login
```

- Ensuite, il faut initialiser terraform

```bash
terraform init 
```

- Ensuite, on récupère l'ID de l'utilisateur

```bash
az ad signed-in-user show --query id -o tsv
```
Il faut copier la sortie.

- Puis, il faut vérifier que tout est correcte en indiquant la valeur copiée au préalable pour user_object_id

```bash
terraform plan -var "user_object_id=<ID>"
```

- Enfin, il faut déployer l'infrastructure en indiquant la valeur copiée au préalable pour user_object_id

```bash
terraform apply -var "user_object_id=<ID>"
```
Entrez yes pour confirmer l'apply, vous devrez attendre 2 à 5 minutres pour que l'infrastructure soit déployée.


### Etape 2 : Partie Docker - Assurez-vous que vous avez lancé Docker au préalable

- Entrer dans le dossier flask-app

```bash
cd ../flask-app
```

- Premièrement, il faut se connecter à notre conteneur de register

```bash
az acr login --name acrdevecijallu
```
Vous devrez voir Login Succeeded

- Puis, il faut créer l'image de notre application à partir du Dockerfile

```bash
docker build -t acrdevecijallu.azurecr.io/flask-app:latest .
```

- Enfin, il faut push l'image

```bash
docker push acrdevecijallu.azurecr.io/flask-app:latest
```

### Etape 3 : Partie Kubernetes

- Naviguer à la racine du projet (devops-project)

```bash
cd ../
```

- Puis, il faut se connecter à notre cluster Kubernetes

```bash
az aks get-credentials --overwrite-existing -n aks-esgi-deveci-jallu -g rg-esgi-deveci-jallu
```

- Ensuite, avant de déployer l'application on va déployer un ingress controller (en utilisant helm) sur le cluster Kubernetes.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```
- puis
```bash
helm repo update
```

- Puis, on va installer l'ingress controller
    - Avant l'installation, on doit aller dans le dossier terraform pour pouvoir récupérer l'adresse IP publique

```bash
cd terraform
```

- puis

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
--namespace flask-app \
--create-namespace \
--set controller.nodeSelector."kubernetes\.io/os"=linux \
--set controller.service.loadBalancerIP=$(terraform output public_ip_address | sed 's/"//g') \
--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
--set defaultBackend.nodeSelector."kubernetes\.io/os"=linux
```

- On revient à la racine du projet

```bash
cd ../
```

- Puis, on va déployer (la première commande va nous donner un warning, mais il n'y a pas de problème)

```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes 
```

- Enfin, on va voir si tout est bien déployé (pour voir les pods, services, ingress, ...) et récupérer l'ip publique dans la ligne "service/ingress-nginx-controller" - External IP
```bash
kubectl get all -n flask-app
```

### Etape 4 : Partie Test

- Pour tester l'application, on peut faire un curl dont PUBLIC-IP est l'ip publique récupérée à l'étape 3

```bash
curl <PUBLIC-IP>
```

Le résultat : This webpage has been viewed \<X> time(s)


### Etape 5 : Partie Nettoyage

- Toujours dans le dossier devops-project, on va supprimer premièrement l'ingress controller

```bash
helm uninstall ingress-nginx -n flask-app
```

- Enfin, on va supprimer la partie kubernetes (penser à faire ctrl + c)

```bash
kubectl delete -f kubernetes
```

- Puis, on va supprimer l'infrastructure où on va indiquer la valeur copiée au préalable pour user_object_id

```bash
cd terraform
terraform destroy -var "user_object_id=<ID>"
```