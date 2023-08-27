# k8s-util - bitnami kubectl image with helm and gettext package included
If you use helm to deploy some application dependecies like MongoDB or MySQL in a GitOps fashion, and use environment variables in your k8s manifests to easily manage multiple projects, you may need a docker image with kubectl, helm, and gettext tools included.

Two common scenarios in my setups is similar to following codes:

## 1- Deploy application kubernetes manifests with a lot of environment variables
**manifests.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: $KUBE_NAMESPACE
---
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: $CI_PROJECT_NAME
spec:
  replicas: 1
  selector:
    matchLabels:
      name: $CI_PROJECT_NAME
  template:
    metadata:
      labels:
        name: $CI_PROJECT_NAME
    spec:
      containers:
        - name: $CI_PROJECT_NAME
          image: $CI_REGISTRY/$CI_PROJECT_NAMESPACE/$CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: $CI_PROJECT_NAME
spec:
  selector:
    name: $CI_PROJECT_NAME
  ports:
  - port: 80
    name: http
    targetPort: http
---
apiVersion: networking.k8s.io/v1 
kind: Ingress
metadata:
  name: $CI_PROJECT_NAME
spec:
  rules:
  - host: $INGRESS_HOST
    http:
      paths:
      - backend:
          service: 
            name: $CI_PROJECT_NAME
            port: 
              name: http
        path: $INGRESS_PATH
        pathType: ImplementationSpecific
```

**.gitlab-ci.yml file:**
```yaml
deploy:
  image:
    name: ghcr.io/ahmadidev/k8s-util
    entrypoint: ['']
  variables:
    KUBE_NAMESPACE: "$CI_PROJECT_NAME-$CI_ENVIRONMENT_NAME"
    INGRESS_HOST: app.domain.tld
    INGRESS_PATH: /
  script:
    - echo "Deploying manifests under $KUBE_NAMESPACE namespace"
    - envsubst < ./manifests.yaml | kubectl apply -f - -n $KUBE_NAMESPACE
```
As you can see, you are free to use all possible envs that are passed by CI engine or defined by you with envsust tool which is included in the k8s-util image. Using env vars, you can easily copy just this two file over other projects and have CICD enabled in no time.

## 2- Deploy application dependencies helm charts
**mongodb-helm-values.yaml:**
```yaml
auth:
  usernames:
  - api
  passwords:
  - api-secret-pass
  databases:
  - app
```

**.gitlab-ci.yml file:**
```yaml
config:
  image: 
    name: reg.apwa.ir/devops/k8s-util
    entrypoint: ['']
  variables:
    KUBE_NAMESPACE: "$CI_PROJECT_NAME-$CI_ENVIRONMENT_NAME"
    HELM_CONFIG_HOME: /tmp/.helm-config/
    HELM_DATA_HOME: /tmp/.helm-data/
    HELM_CACHE_HOME: /tmp/.helm-cache/
  script:
    # KUBECONFIG file is mounted from gitlab-runner to the container
    - helm version
    - helm repo add bitnami https://charts.bitnami.com/bitnami
    - helm upgrade --install mongodb bitnami/mongodb --namespace=$KUBE_NAMESPACE --create-namespace --version=13.10.1 --values=mongodb-helm-values.yaml
```
In this setup you only need a docker executor runner and this image to easily deploy and manage your application dependencies.
