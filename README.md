# A9 Default Helm Chart

Chart Helm padrão do **A9 Catalog** para deploy de aplicações no Kubernetes (EKS).

## Visão Geral

Este é o chart base utilizado por todas as aplicações da A9 Tecnologia. Ele fornece uma configuração padronizada e pronta para produção com suporte a:

- ✅ Deployment com recursos configuráveis
- ✅ Service e Ingress (AWS ALB)
- ✅ ConfigMaps e Secrets
- ✅ ServiceAccount com IRSA
- ✅ Init Containers
- ✅ Horizontal Pod Autoscaler (HPA)
- ✅ Pod Disruption Budget (PDB)
- ✅ Topology Spread Constraints (distribuição entre AZs)
- ✅ ArgoCD Image Updater
- ✅ Probes configuráveis

## Instalação

```bash
helm repo add a9-catalog https://a9org.github.io/helm-default-apps
helm install my-app a9-catalog/app -f values.yaml
```

## Configuração Básica

### Exemplo Mínimo

```yaml
image:
  repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app
  tag: "1.0.0"

ingress:
  enabled: true
  host: myapp.example.com
  certificateArn: arn:aws:acm:us-east-1:123456789012:certificate/xxx
  subnets: subnet-xxx,subnet-yyy
```

### Exemplo Completo

```yaml
replicaCount: 3

image:
  repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app
  tag: "1.2.3"
  pullPolicy: IfNotPresent

labels:
  team: platform
  cost-center: engineering

resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

podDisruptionBudget:
  enabled: true
  minAvailable: 2

topologySpreadConstraints:
  enabled: true
  maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: ScheduleAnyway

probes:
  readiness:
    enabled: true
    path: /health
    initialDelaySeconds: 10
    periodSeconds: 10
  liveness:
    enabled: true
    path: /health
    initialDelaySeconds: 30
    periodSeconds: 20

service:
  type: ClusterIP
  app:
    port: 80
    targetPort: 8080

ingress:
  enabled: true
  host: myapp.a9-developmente.click
  groupName: production-apps
  certificateArn: arn:aws:acm:us-east-1:123456789012:certificate/xxx
  subnets: subnet-xxx,subnet-yyy
  healthcheckPath: /health

configMap:
  enabled: true
  data:
    APP_ENV: production
    LOG_LEVEL: info
    API_URL: https://api.example.com

secret:
  enabled: true
  data:
    DATABASE_PASSWORD: mypassword
    API_KEY: myapikey

env:
  plain:
    - name: NODE_ENV
      value: production

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-app-role

argocd:
  imageUpdater:
    enabled: true
    strategy: semver
    constraint: "^1.0"
    tagPrefix: "prd-"
    autoUpdate: true
```

## Recursos Principais

### 1. Resources (Requests e Limits)

Define limites de CPU e memória para os containers:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 2. Horizontal Pod Autoscaler (HPA)

Escalonamento automático baseado em CPU/memória:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

> **Nota:** Quando HPA está habilitado, o `replicaCount` é ignorado.

### 3. Pod Disruption Budget (PDB)

Garante disponibilidade durante atualizações:

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1
  # OU
  # maxUnavailable: 1
```

### 4. Topology Spread Constraints

Distribui pods entre múltiplas Availability Zones:

```yaml
topologySpreadConstraints:
  enabled: true
  maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: ScheduleAnyway
```

### 5. Probes Configuráveis

Healthchecks totalmente customizáveis:

```yaml
probes:
  readiness:
    enabled: true
    path: /health
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 5
    successThreshold: 1
    failureThreshold: 3
  liveness:
    enabled: true
    path: /health
    initialDelaySeconds: 15
    periodSeconds: 20
    timeoutSeconds: 5
    successThreshold: 1
    failureThreshold: 3
```

### 6. ArgoCD Image Updater

Atualização automática de imagens:

```yaml
argocd:
  imageUpdater:
    enabled: true
    strategy: semver          # semver, latest, digest, name
    constraint: "^1.0"        # Constraint semver
    tagPrefix: "prd-"         # Prefixo da tag (ex: prd-1.0.0)
    autoUpdate: true
```

**Estratégias disponíveis:**
- `semver`: Semantic versioning (recomendado)
- `latest`: Última tag disponível
- `digest`: Por digest SHA
- `name`: Por nome da tag

**Exemplos de constraint:**
- `^1.0` - Versões 1.x.x
- `~1.2` - Versões 1.2.x
- `>=1.0.0 <2.0.0` - Range específico

### 7. Init Containers

Para executar tarefas antes do container principal (migrations, setup, etc):

```yaml
initContainer:
  enabled: true
  command:
    - sh
    - -c
  args:
    - npm run migrate
  env:
    plain:
      - name: RUN_MIGRATIONS
        value: "true"
```

Resources específicos para init container:

```yaml
initContainerResources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

### 8. ServiceAccount com IRSA

Para acesso a recursos AWS via IAM Roles:

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-app-role
```

### 9. ConfigMaps e Secrets

**ConfigMap:**
```yaml
configMap:
  enabled: true
  data:
    APP_ENV: production
    LOG_LEVEL: info
```

**Secret:**
```yaml
secret:
  enabled: true
  data:
    DATABASE_PASSWORD: mypassword
    API_KEY: myapikey
```

**Variáveis diretas:**
```yaml
env:
  plain:
    - name: NODE_ENV
      value: production
```

### 10. Labels Customizados

Para organização e rastreabilidade:

```yaml
labels:
  team: platform
  cost-center: engineering
  environment: production
```

Aplicados automaticamente em: Deployment, Pods, HPA e PDB.

## Ingress (AWS ALB)

O chart usa AWS Load Balancer Controller para criar ALBs:

```yaml
ingress:
  enabled: true
  host: myapp.example.com
  groupName: production-apps        # Agrupa múltiplos ingress no mesmo ALB
  certificateArn: arn:aws:acm:...
  subnets: subnet-xxx,subnet-yyy    # Subnets públicas
  healthcheckPath: /health
  annotations: {}                    # Annotations adicionais
```

## Estrutura do Chart

```
.
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   └── _helpers.tpl
└── README.md
```

## Boas Práticas

1. **Sempre defina resources** - Evita problemas de scheduling e OOM
2. **Use HPA em produção** - Garante elasticidade
3. **Habilite PDB** - Mantém disponibilidade durante updates
4. **Configure topology spread** - Distribui carga entre AZs
5. **Use IRSA** - Evita credenciais hardcoded
6. **Prefira semver no Image Updater** - Controle de versões previsível
7. **Ajuste probes** - Conforme tempo de startup da aplicação

## Troubleshooting

### Pods não iniciam

Verifique resources e probes:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### HPA não escala

Certifique-se que metrics-server está instalado:
```bash
kubectl top nodes
kubectl top pods
```

### Ingress não cria ALB

Verifique AWS Load Balancer Controller:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Suporte

- **Documentação:** https://docs.a9-developmente.click/
- **Repositório:** https://github.com/a9org/helm-default-apps
- **Equipe:** Engenharia A9 Tecnologia


