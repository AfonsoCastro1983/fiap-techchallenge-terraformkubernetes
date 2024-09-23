# Lanchonete FIAP - Terraform Infrastructure

Este repositório contém a configuração de infraestrutura da aplicação "Lanchonete FIAP" utilizando o Terraform para provisionamento na AWS.

## Recursos Provisionados

### 1. **VPC (Virtual Private Cloud)**
- **Recurso:** `aws_vpc.lanchoneteFIAP`
- **Descrição:** Cria uma VPC com o bloco CIDR `10.0.0.0/16`, habilitando suporte a DNS e hostnames.
- **Tags:** `lanchoneteFIAP-vpc`

### 2. **Subnets**
#### Subnet A:
- **Recurso:** `aws_subnet.subnetA`
- **Descrição:** Subnet pública localizada na zona de disponibilidade `us-east-2a`, com bloco CIDR `10.0.1.0/24`.
- **Tags:** `lanchoneteFIAP-subnetA`

#### Subnet B:
- **Recurso:** `aws_subnet.subnetB`
- **Descrição:** Subnet pública localizada na zona de disponibilidade `us-east-2b`, com bloco CIDR `10.0.2.0/24`.
- **Tags:** `lanchoneteFIAP-subnetB`

### 3. **Internet Gateway**
- **Recurso:** `aws_internet_gateway.igw`
- **Descrição:** Internet Gateway associado à VPC para permitir acesso à internet.
- **Tags:** `lanchoneteFIAP-igw`

### 4. **Tabela de Rotas**
- **Recurso:** `aws_route_table.rt`
- **Descrição:** Configura rota para o tráfego da VPC, direcionando o tráfego de saída (CIDR `0.0.0.0/0`) através do Internet Gateway.
- **Tags:** `lanchoneteFIAP-rt`

### 5. **Security Group para EKS**
- **Recurso:** `aws_security_group.eks_sg`
- **Descrição:** Security Group para o cluster EKS, permitindo todo o tráfego (porta 0-0 e protocolo `-1`).
- **Tags:** `lanchoneteFIAP-eks-sg`

### 6. **Cluster EKS (Elastic Kubernetes Service)**
- **Recurso:** `aws_eks_cluster.eks`
- **Descrição:** Cluster EKS que utiliza as subnets criadas e o Security Group associado.
- **Role:** `aws_iam_role.eks_role`

### 7. **IAM Role para EKS**
- **Recurso:** `aws_iam_role.eks_role`
- **Descrição:** Role necessária para permitir que o EKS tenha permissões de criação e gestão de recursos AWS.

### 8. **Node Group EKS**
- **Recurso:** `aws_eks_node_group.eks_node_group`
- **Descrição:** Configura um grupo de nós para o cluster EKS com `t3.small` instâncias e tamanho de cluster de 2 nós.
- **Role:** `aws_iam_role.eks_node_role`

### 9. **IAM Role para Node Group do EKS**
- **Recurso:** `aws_iam_role.eks_node_role`
- **Descrição:** Role para instâncias EC2 dentro do Node Group, permitindo a execução dos nós do EKS.

## Configuração do GitHub Actions

O repositório também inclui uma configuração para automação de deploy da infraestrutura utilizando GitHub Actions. Toda vez que uma alteração é enviada para a branch `main`, o GitHub Actions executa um fluxo de deploy que inclui:

### Passos:

1. **Checkout do código:**
   - Utiliza a ação `actions/checkout@v2` para baixar o código-fonte do repositório.

2. **Configuração do Terraform:**
   - Utiliza a ação `hashicorp/setup-terraform@v1` para configurar o ambiente do Terraform.

3. **Configuração das credenciais AWS:**
   - Utiliza a ação `aws-actions/configure-aws-credentials@v1` para configurar as credenciais de acesso à AWS, usando secrets armazenados no GitHub (`AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`).

4. **Inicialização do Terraform:**
   - Executa `terraform init` para inicializar o ambiente Terraform e baixar os módulos e provedores necessários.

5. **Importação de recursos existentes:**
   - Importa a VPC e o Subnet Group do RDS, garantindo que o estado do Terraform reflita a infraestrutura já existente na AWS.

6. **Plano do Terraform:**
   - Executa `terraform plan` para gerar o plano de execução e revisar as mudanças que serão aplicadas.

7. **Aplicação do Terraform:**
   - Executa `terraform apply -auto-approve` para aplicar automaticamente as alterações na infraestrutura, caso o código esteja na branch `main`.

### Fluxo de Trabalho

Este fluxo é acionado em qualquer push para a branch `main`, garantindo que todas as alterações no código de infraestrutura sejam refletidas automaticamente no ambiente AWS, sem intervenção manual.

---

Este repositório segue as melhores práticas de IaC (Infrastructure as Code) com o uso de Terraform e GitHub Actions para um processo de deploy automatizado e seguro.