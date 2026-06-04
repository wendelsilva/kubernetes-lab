# Cluster Kubernetes Local com Automação IaC
## Resumo
Este repositório contém toda a estrutura e automação necessárias para levantar um laboratório completo de
Kubernetes em ambiente de desenvolvimento local. O objetivo principal do desafio foi criar uma infraestrutura
robusta, resiliente e totalmente reprodutível utilizando conceitos modernos de Infrastructure as Code (IaC).

A arquitetura simula um ambiente de produção real em miniatura. Ela é composta por um nó de Control
Plane e dois nós Workers rodando Ubuntu 22.04 LTS. Para dar vida ao cluster, implementei uma
aplicação prática de gerenciamento de tarefas (ToDo App) desenvolvida em Golang, integrada a um banco
de dados PostgreSQL com persistência real de dados. Toda a camada de orquestração interna
(Deployments, Services, Persistent Volumes, Secrets, Ingress Controller e Network Policies) foi padronizada
e automatizada de ponta a ponta via Terraform.

## Requisitos do Sistema e Pré-requisitos
### Hardware Recomendado
- [ ] Processador: Mínimo de 4 núcleos físicos (Ex: Intel Core i5 de 11a Geração ou equivalente).
- [ ] Memória RAM: 8 GB no mínimo (O laboratório consome exatamente 4 GB dedicados para as VMs, preservando o restante para o sistema operacional host).
- [ ] Sistema Operacional Host: Distribuições Linux (Testado e validado nativamente no Linux Mint 22.3
XFCE / Ubuntu 22.04).

## Dependências Técnicas (Softwares que você precisa instalar)
Antes de iniciar, garanta que as seguintes ferramentas estejam instaladas e configuradas no seu terminal:
- [ ] KVM / libvirt: O provider de virtualização hipervisor padrão usado pelo Vagrant neste projeto para garantir
performance nativa de kernel no Linux.
- [ ] Vagrant (v2.3+): Responsável por gerenciar o ciclo de vida das máquinas virtuais.
- [ ] Terraform (v1.5+): Ferramenta declarativa que aplicará todos os manifests e configurações no cluster
Kubernetes.
- [ ] Plugin Vagrant-Libvirt: Extensão necessária para que o Vagrant converse com o KVM.

## Passo a Passo: Execução do Laboratório
Siga a sequência abaixo para implantar a stack completa:

### Clonar o Repositório
Abra o terminal da sua máquina física e traga o projeto localmente:
```bash
git clone https://github.com/wendelsilva/kubernetes-lab.git
cd kubernetes-lab
```

### Executar o Vagrant
Nesse passo será necessário informar a senha do usuário para que o Vagrant possa criar as máquinas virtuais utilizando o KVM/libvirt.
```bash
vagrant up --provider=libvirt
```

### Executar o Terraform
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### Configuração de DNS Local e Validação Comercial
Para conseguir acessar o Ingress utilizando o domínio simulado através do navegador do seu computador
host, precisamos apontar a resolução de nomes. Insira a linha abaixo no arquivo /etc/hosts da sua
máquina física:
```bash
192.168.56.12 app.k8s.local
```
Talvez o ip seja diferente, então verifique o IP do nó em que a aplicação está rodando.

## Decisões Técnicas
- [ ] Vagrant + KVM/libvirt: Escolha crucial de arquitetura. O VirtualBox consome muita sobrecarga de CPU/
RAM em ecossistemas Linux. O KVM atua diretamente no nível do kernel, garantindo uma virtualização
incrivelmente leve e rápida, ideal para o teto de 8 GB de RAM disponível no host.
- [ ] Calico CNI: Optei pelo Calico ao invés de soluções mais simples (como o Flannel) devido ao requisito
mandatório de segurança do desafio: o isolamento de rede nativo por meio de objetos do tipo
NetworkPolicy .
- [ ] Terraform como Gerenciador de Estado do K8s: Em vez de lidar com dezenas de arquivos YAML
soltos aplicados via kubectl apply , usei o Terraform. Isso dá controle absoluto sobre
dependências, ordem de provisionamento (o banco de dados sempre sobe antes da aplicação) e
facilidade para destruir o ambiente de forma limpa ( terraform destroy ).
- [ ] Build Multi-Stage em Golang (Imagem Base Scratch): A aplicação Go foi compilada em ambiente de
build isolado no Dockerfile e seu binário estático foi jogado dentro de uma imagem limpa do tipo
scratch.