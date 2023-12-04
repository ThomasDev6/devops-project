# Rendu : Deveci Serkan et Jallu Thomas
## Ecrivez ici les inscriptions et explications pour déployer l'infrastructure et l'application sur Azure

### Prérequis
#### Assurez-vous d'avoir les outils suivants :
- Terraform
- Azure CLI
- Docker
- Helm

### Etape 1 : Partie Terraform

- Entrer dans le dossier <span style="color:cyan">terraform</span>

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

- Puis, il faut vérifier que tout est correcte

```bash
terraform plan
```

- Enfin, il faut déployer l'infrastructure

```bash
terraform apply
```
Entrez<span style="color:red"> yes </span>pour confirmer l'apply, vous devrez attendre 2 à 5 minutres pour que l'infrastructure soit déployée.


### Etape 2 : Partie Docker - <span style="color:green">Assurez-vous que vous avez lancé Docker au préalable</span>

- Entrer dans le dossier <span style="color:cyan">flask-app</span>

```bash
cd ../flask-app
```

- Premièrement, il faut se connecter à notre conteneur de register

```bash
az acr login --name acrdevecijallu
```
Vous devrez voir <span style="color:green">Login Succeeded</span>

- Puis, il faut créer l'image de notre application à partir du Dockerfile

```bash
docker build -t acrdevecijallu.azurecr.io/flask-app:latest .
```

- Enfin, il faut push l'image

```bash
docker push acrdevecijallu.azurecr.io/flask-app:latest
```

### Etape 3 : Partie Kubernetes

- Naviguer à la racine du projet <span style="color:cyan">(devops-project)</span>

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

Le résultat : <span style="color:green">This webpage has been viewed \<X> time(s)</span>


### Etape 5 : Partie Nettoyage

- Toujours dans le dossier <span style="color:cyan">devops-project</span>, on va supprimer premièrement l'ingress controller

```bash
helm uninstall ingress-nginx -n flask-app
```

- Enfin, on va supprimer la partie kubernetes (penser à faire ctrl + c)

```bash
kubectl delete -f kubernetes
```

- Puis, on va supprimer l'infrastructure

```bash
cd terraform
terraform destroy
```