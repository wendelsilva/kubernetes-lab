# Cluster Kubernetes Local com Automação IaC
## Resumo
Neste repositório, apresento toda a estrutura e automação necessárias para levantar um laboratório completo de Kubernetes em ambiente de desenvolvimento local. Meu principal objetivo neste desafio foi criar uma infraestrutura robusta, resiliente e totalmente reprodutível utilizando conceitos modernos de Infrastructure as Code (IaC).

Para este projeto, desenvolvi uma arquitetura que simula um ambiente de produção em miniatura. Para dar vida ao cluster, implementei uma
aplicação prática de gerenciamento de tarefas (ToDo App) desenvolvida em Golang, integrada a um banco
de dados PostgreSQL com persistência real de dados.

## Requisitos do Sistema e Pré-requisitos
### Hardware Recomendado
- [ ] Processador: Mínimo de 4 núcleos físicos (Ex: Intel Core i5 de 11a Geração ou equivalente).
- [ ] Memória RAM: Mínimo de 8 GB (o laboratório consome aproximadamente 4 GB dedicados às VMs, preservando o restante para o sistema operacional host).
- [ ] Sistema Operacional Host: Distribuições Linux (Testado e validado nativamente no Linux Mint 22.3
XFCE / Ubuntu 22.04).

## Dependências Técnicas (Softwares que você precisa instalar)
Antes de iniciar, garanta que as seguintes ferramentas estejam instaladas e configuradas no seu terminal:
- [ ] KVM / libvirt: O provider de virtualização hipervisor padrão usado pelo Vagrant neste projeto para garantir
performance nativa de kernel no Linux.
- [ ] Vagrant (v2.3+): Responsável por gerenciar o ciclo de vida das máquinas virtuais.
- [ ] Terraform (v1.5+): Ferramenta declarativa que aplicará todos os manifests e configurações no cluster
Kubernetes.
- [ ] Plugin Vagrant-Libvirt: extensão necessária para permitir a integração entre o Vagrant e o KVM/libvirt.

## Passo a Passo: Execução do Laboratório
Siga a sequência abaixo para implantar a stack completa:

### Clonar o Repositório:
```bash
git clone https://github.com/wendelsilva/kubernetes-lab.git
cd kubernetes-lab
```

### Executar o Vagrant
Neste passo, será necessário informar a senha do usuário para que o Vagrant possa criar as máquinas virtuais utilizando o KVM/libvirt.
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
máquina:
```bash
192.168.56.12 app.k8s.local
```
O IP pode ser diferente do exemplo acima. Nesse caso, verifique o endereço do nó onde a aplicação está sendo executada e atualize o arquivo /etc/hosts.

## Decisões Técnicas
- [ ] Vagrant + KVM/libvirt: Escolha crucial de arquitetura. O VirtualBox consome muita sobrecarga de CPU/
RAM em ecossistemas Linux. O KVM atua diretamente no nível do kernel, garantindo uma virtualização
incrivelmente leve e rápida, ideal para o teto de 8 GB de RAM disponível no host.
- [ ] Calico CNI: Optei pelo Calico em vez de soluções mais simples (como o Flannel) devido ao requisito
mandatório de segurança do desafio: o isolamento de rede nativo por meio de objetos do tipo
NetworkPolicy .
- [ ] Terraform como Gerenciador de Estado do K8s: Em vez de lidar com dezenas de arquivos YAML aplicados manualmente via kubectl apply, utilizei o Terraform como ferramenta central de gerenciamento da infraestrutura Kubernetes.
- [ ] Build Multi-Stage em Golang (Imagem Base Scratch): Compilei a aplicação Go em um estágio isolado de build no Dockerfile e publiquei o binário estático em uma imagem mínima baseada em scratch.

## Resultados Obtidos

Com essa implementação consegui:

- Provisionar um cluster Kubernetes com 1 nó Control Plane e 2 nós Workers;
- Implantar uma aplicação Go com banco PostgreSQL;
- Gerenciar toda a infraestrutura utilizando Terraform;
- Implementar persistência de dados;
- Configurar Ingress Controller e Network Policies;
- Garantir que todo o ambiente possa ser recriado de forma automatizada e reproduzível.