# ProjectC07_SystemMarket

### Integrantes:
Luan Pierre de Paula - 376
Igor Silva Toledo - 533

### Tema:
O banco de dados tem por finalidade simular um sistema de supermercado, sendo os usuários principais, os funcionários. A ideia e ter um sistema minimalista do que seria necessário para armazenar esse tipo de informação com mais performance, visando mais a organização dos dados e da performance.


## Estrutura 

- **Criação do Banco de Dados:** O sistema prepara e seleciona a área exclusiva onde todas as informações e tabelas do projeto serão armazenadas.
- **Configuração de Segurança Inicial:** Desabilita temporariamente as travas de validação para permitir a inserção segura dos primeiros administradores do sistema.
- **Estrutura de Cadastro de Usuários:** Cria a tabela principal para salvar dados dos colaboradores e tabelas extras para identificar se trabalham de forma presencial ou remota.
- **Cadastro dos Primeiros Usuários:** Realiza a inserção no sistema dos dois desenvolvedores responsáveis pela criação e início do projeto.
- **Restauração de Segurança:** Reativa as travas de validação de dados para garantir que nenhuma informação futura seja inserida de forma incorreta.
- **Estrutura de Cargos:** Cria a tabela que define as funções profissionais e insere os cargos de Desenvolvedor e Diretor.
- **Estrutura de Níveis de Acesso:** Cria a tabela que controla o que cada um pode ver no sistema e define os acessos iniciais.
- **Ajuste de Termo Técnico:** Altera o nome de um nível de acesso de "Majoritário" para "Developer" por decisão da equipe de desenvolvimento.
- **Vínculo Obrigatório de Funções:** Atualiza os primeiros usuários e modifica a regra para que nenhum funcionário novo seja cadastrado sem um cargo ou nível de acesso.
- **Cadastro do Proprietário:** Insere as informações do dono da empresa no banco de dados de usuários.
- **Regra de Proteção de Senhas:** Cria um validador automático que impede os usuários de criarem senhas contendo seus próprios nomes ou datas de nascimento.
- **Estrutura Organizacional Comercial:** Cria as tabelas para organizar a empresa em Departamentos, Grupos de produtos e Famílias de itens.
- **Estrutura de Responsabilidades:** Cria a tabela que define quais funcionários cuidam de quais setores e famílias de produtos da empresa.
- **Estrutura de Fornecedores e Marcas:** Cria tabelas para catalogar as indústrias parceiras, as distribuidoras de mercadorias e as marcas comerciais dos produtos.
- **Estrutura de Estoque de Produtos:** Cria a tabela que armazena o catálogo de itens vendidos, contendo códigos, preços de custo e preços de venda.
- **Estrutura de Pedidos de Compra:** Cria a tabela que registra as solicitações de reposição de mercadorias feitas pelos funcionários.



  ## Populando Dados
 
- **Alimentação de Dados do Sistema:** Realiza uma grande inserção de diversos cargos, níveis de acesso, funcionários, departamentos, grupos, famílias, empresas, marcas e produtos.
- **Histórico de Pedidos:** Registra uma lista com diversas solicitações de compras realizadas em datas diferentes pela equipe.

- ## Pesquisa Performatica de alguns dados
 
- **Consulta de Desempenho de Vendas:** Roda um relatório para listar quais produtos possuem pedidos realizados e quais nunca foram solicitados.



  ## Configurando Privilgios de controle e acesso ao Banco
 
- **Gerenciamento de Usuários do Banco:** Cria contas de acesso para os membros da equipe e define quais permissões de leitura ou modificação cada um terá.
- **Ajuste e Verificação de Permissões:** Remove acessos desnecessários de segurança, valida as permissões na tela e cria grupos de privilégios para os assistentes e donos.
- **Automatização de Consultas de Usuários:** Cria e testa duas ferramentas de busca rápida para listar todos os funcionários ativos ou encontrar um específico pelo código.



  ## Otimização de Comandos utilizando Procedures
 
- **Criação e Remoção de Calculadora:** Cria temporariamente uma ferramenta para calcular o lucro das vendas e a remove logo em seguida.
- **Criação de Relatório Visual:** Desenvolve uma janela de visualização simplificada para exibir rapidamente os grupos de produtos cadastrados.
- **Atualização Automática de Data:** Cria um mecanismo que salva automaticamente o dia e horário exato em que qualquer dado de usuário for modificado.



  ## Automação para Remoção, utilizando Trigger
  
- **Limpeza de Relatório:** Deleta a janela de visualização criada anteriormente para manter o ambiente limpo.
