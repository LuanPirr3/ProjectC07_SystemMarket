CREATE DATABASE IF NOT EXISTS c07;

USE c07;

-- Como o Usuario é fortemente restrito, para a inserção do primeiro usuario será necessário
-- desabilitar temporariamente a checagem de chave estrangeira
SET FOREIGN_KEY_CHECKS = 0;

-- Criando Tabela Usuario

CREATE TABLE IF NOT EXISTS c07.TBUSUARIO(								
	id 				int	 			UNSIGNED						NOT NULL,
	nome			varchar(30)												,
	nome_sistema	varchar(30)								UNIQUE	NOT NULL,
	senha			varchar(15)										NOT NULL,
	email			varchar(100)											,
	data_update		TIMESTAMP 												,
	data_nascimento	DATE 													,
	ativo			BOOLEAN											NOT NULL,
	id_cargo		SMALLINT		UNSIGNED								,
	id_nivl_acesso	SMALLINT		UNSIGNED								,
	id_res_adicao	int				UNSIGNED								,
	id_ult_ativacao	int				UNSIGNED								,
	
	PRIMARY KEY (id),
	UNIQUE(email),
	FOREIGN KEY(id_res_adicao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_ult_ativacao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_nivl_acesso) REFERENCES c07.TBNIVEL_ACESSO(id),
	FOREIGN KEY(id_cargo) REFERENCES c07.TBCARGO(id)
);

-- Inserindo os usuarios dev para realizar as primeiras inserções
INSERT INTO c07.TBUSUARIO(id, nome, nome_sistema, senha, email, data_update, data_nascimento, ativo) VALUES
(1, 'Igor Toledo', 'DEV_Igor', 'teste123', 'igor@gmail.com', current_timestamp, '2001-01-01', true),
(2, 'Luan Pierre', 'DEV_Luan', 'teste1wa', 'luan@gmail.com', current_timestamp, '2001-01-01', true);

-- Criando Tabela TBUSU_REMOTO

CREATE TABLE IF NOT EXISTS TBUSU_REMOTO (
	id				int				UNSIGNED						NOT NULL,
	ip_remoto		varchar(45)										NOT NULL,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id) REFERENCES TBUSUARIO(id)
);

-- Criando Tabela TBUSU_PRESENCIAL
CREATE TABLE IF NOT EXISTS TBUSU_PRESENCIAL(
	id				int				UNSIGNED						NOT NULL,
	ip_local		varchar(45)										NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(id) REFERENCES TBUSUARIO(id)
);

-- Habilitando a checagem de chaves estrangeiras novamente
SET FOREIGN_KEY_CHECKS = 1;

-- Criando tabela Cargo

CREATE TABLE IF NOT EXISTS c07.TBCARGO (
	id				SMALLINT		UNSIGNED 	AUTO_INCREMENT 		NOT NULL,
	cargo			varchar(50)										NOT NULL,
	ativo			boolean											NOT NULL,
	id_ult_ativacao	int				UNSIGNED						NOT NULL,
	id_res_adicao	int				UNSIGNED						NOT NULL,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_ult_ativacao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_res_adicao) REFERENCES c07.TBUSUARIO(id),
	UNIQUE (cargo)
);

-- Inserindo Cargos para os devs e o dono

INSERT INTO c07.TBCARGO(cargo, ativo, id_res_adicao, id_ult_ativacao) VALUES
('Developer', true, 1, 1),
('Diretor', true, 2, 2);

-- Criando tabela Nivel de acesso

CREATE TABLE IF NOT EXISTS c07.TBNIVEL_ACESSO (
	id				SMALLINT		UNSIGNED	AUTO_INCREMENT		NOT NULL,
	acesso			varchar(50)										NOT NULL,
	ativo			boolean											NOT NULL,
	id_ult_ativacao	int				UNSIGNED						NOT NULL,
	id_res_adicao	int				UNSIGNED						NOT NULL,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_ult_ativacao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_res_adicao) REFERENCES c07.TBUSUARIO(id),
	UNIQUE(acesso)
);

INSERT INTO c07.TBNIVEL_ACESSO(acesso, ativo, id_res_adicao, id_ult_ativacao) VALUES
('Majoritario', true, 1, 1),
('OWNER', true, 2, 2);

-- O Dev Luan acha que majoritário não é um bom nome para um nivel de acesso de desenvolvedores
-- então ele decidiu mudar para DEVELOPER

UPDATE c07.TBNIVEL_ACESSO SET acesso = 'DEVELOPER' WHERE acesso = 'Majoritario';

-- Agora precisamos atualisar os dados para que quando atribuimos Not Null em tbusuario
-- para que não ocorra nenhum erro

UPDATE c07.TBUSUARIO SET id_cargo = 1, id_nivl_acesso = 1, id_res_adicao = 1, id_ult_ativacao = 1 WHERE id IN (1, 2);

-- Alterando as Colunas para NOT NULL, para que novos usuarios estejam atrelados a um cargo, nivel de acesso, e o id de quem adicionou ele ao banco
ALTER TABLE c07.TBUSUARIO 
MODIFY COLUMN id_cargo SMALLINT UNSIGNED NOT NULL, 
MODIFY COLUMN id_nivl_acesso SMALLINT UNSIGNED NOT NULL,
MODIFY COLUMN id_res_adicao INT UNSIGNED NOT NULL,
MODIFY COLUMN id_ult_ativacao INT  UNSIGNED NOT NULL;

-- Inserindo o cadastro do Dono

INSERT INTO c07.TBUSUARIO(id, nome, nome_sistema, senha, email, data_update, data_nascimento, ativo, id_cargo, id_nivl_acesso, id_res_adicao, id_ult_ativacao) VALUES
(3, 'Pedro Ferreira Paulo', 'Pedro Ferreira', '3131231', 'pedro@gmail.com', current_timestamp(), '1974-3-12', true, 2, 2, 1, 1); 

-- Trgigger de checagem,  antes de ocorrer a inserção verifica se na senha dos próximos usuarios
-- contem parte de nome ou data nascimento
DELIMITER $$

DROP TRIGGER IF EXISTS c07.TRG_VALIDA_SENHA_USUARIO$$

CREATE TRIGGER c07.TRG_VALIDA_SENHA_USUARIO BEFORE INSERT ON c07.TBUSUARIO FOR EACH ROW
BEGIN
    IF NEW.nome IS NOT NULL AND NEW.nome <> '' THEN
	
        IF INSTR(LOWER(NEW.senha), LOWER(TRIM(NEW.nome))) > 0 THEN
            SIGNAL SQLSTATE '45000' -- Cada signal funciona como um break para que a inserção não ocorra
            SET MESSAGE_TEXT = 'Erro de Segurança: A senha não pode conter o seu nome completo.';
        END IF;

        IF INSTR(LOWER(NEW.senha), LOWER(SUBSTRING_INDEX(TRIM(NEW.nome), ' ', 1))) > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Erro de Segurança: A senha não pode conter o seu primeiro nome.';
        END IF;

        IF INSTR(NEW.nome, ' ') > 0 THEN
            IF INSTR(LOWER(NEW.senha), LOWER(SUBSTRING_INDEX(TRIM(NEW.nome), ' ', -1))) > 0 THEN
                SIGNAL SQLSTATE '45000' 
                SET MESSAGE_TEXT = 'Erro de Segurança: A senha não pode conter o seu último sobrenome.';
            END IF;
        END IF;

    END IF;

    IF NEW.data_nascimento IS NOT NULL THEN
        
        IF INSTR(NEW.senha, DATE_FORMAT(NEW.data_nascimento, '%Y')) > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Erro de Segurança: A senha não pode conter o seu ano de nascimento.';
        END IF;

        IF INSTR(NEW.senha, DATE_FORMAT(NEW.data_nascimento, '%d-%m-%Y')) > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Erro de Segurança: A senha não pode conter sua data de nascimento (DD-MM-AAAA).';
        END IF;

        IF INSTR(NEW.senha, DATE_FORMAT(NEW.data_nascimento, '%d/%m/%Y')) > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Erro de Segurança: A senha não pode conter sua data de nascimento (DD/MM/AAAA).';
        END IF;
    END IF;
END$$

DELIMITER ;

-- Criando Tabela Departamento

CREATE TABLE IF NOT EXISTS c07.TBDEPARTAMENTO (
	id				SMALLINT		UNSIGNED	AUTO_INCREMENT		NOT NULL,
	departamento	varchar(50)										NOT NULL,
	codigo			int												NOT NULL,
	ativo			boolean											NOT	NULL,
	id_ult_ativacao	int				UNSIGNED						NOT NULL,
	id_res_adicao	int				UNSIGNED						NOT NULL,
	
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_ult_ativacao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_res_adicao) REFERENCES c07.TBUSUARIO(id),
	UNIQUE(departamento)
);

-- Criando Tabela Grupo

CREATE TABLE IF NOT EXISTS c07.TBGRUPO (
	id				SMALLINT		UNSIGNED	AUTO_INCREMENT		NOT NULL,
	grupo			varchar(50)										NOT NULL,
	codigo			int				UNSIGNED						NOT NULL,
	ativo			boolean											NOT NULL,
	id_ult_ativacao	int				UNSIGNED						NOT NULL,
	id_res_adicao	int				UNSIGNED						NOT NULL,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_ult_ativacao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_res_adicao) REFERENCES c07.TBUSUARIO(id),
	UNIQUE (grupo)
	);
	
-- Criando Tabela Familia
	
CREATE TABLE IF NOT EXISTS c07.TBFAMILIA (
	id				SMALLINT		UNSIGNED	AUTO_INCREMENT		NOT NULL,
	familia			varchar(50)										NOT NULL,
	id_retguarda	int				UNSIGNED						NOT NULL,
	ativo			boolean											NOT NULL,
	id_ult_ativacao	int				UNSIGNED						NOT NULL,
	id_res_adicao	int				UNSIGNED						NOT NULL,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_ult_ativacao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_res_adicao) REFERENCES c07.TBUSUARIO(id),
	UNIQUE(familia)
);

-- Criando Tabela Usuario Departamento

CREATE TABLE IF NOT EXISTS c07.TBUSU_RESPONSAVEL (
	id				int				UNSIGNED	AUTO_INCREMENT		NOT NULL,
	id_usuario		int				UNSIGNED						NOT NULL,
	id_departamento	SMALLINT		UNSIGNED						NOT NULL,
	id_grupo		SMALLINT		UNSIGNED						NOT NULL,
	id_familia		SMALLINT		UNSIGNED						NOT NULL,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_usuario) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_departamento) REFERENCES c07.TBDEPARTAMENTO(id),
	FOREIGN KEY(id_grupo) REFERENCES c07.TBGRUPO(id),
	FOREIGN KEY(id_familia) REFERENCES c07.TBFAMILIA(id)
);

-- Criando Tabela Produto Marca Empresa

CREATE TABLE IF NOT EXISTS c07.TBPRO_MAR_EMPRESA (
	id				SMALLINT		UNSIGNED	AUTO_INCREMENT		NOT NULL,
	empresa			varchar(50)										NOT NULL,
	ativo			boolean											NOT NULL,
	id_ult_ativacao	int				UNSIGNED						NOT NULL,
	id_res_adicao	int				UNSIGNED						NOT NULL,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_ult_ativacao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_res_adicao) REFERENCES c07.TBUSUARIO(id),
	UNIQUE(empresa)
);

-- Criando Tabela Produto Marca Distribuidor

CREATE TABLE IF NOT EXISTS c07.TBPRO_MAR_DISTRIBUIDOR (
	id				SMALLINT		UNSIGNED	AUTO_INCREMENT		NOT NULL,
	distribuidor	varchar(50)										NOT NULL,
	ativo			boolean											NOT NULL,
	id_res_adicao	int				UNSIGNED						NOT NULL,
	id_ult_ativacao	int				UNSIGNED						NOT NULL,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_ult_ativacao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_res_adicao) REFERENCES c07.TBUSUARIO(id),
	UNIQUE(distribuidor)
);

-- Criando Tabela Marca 

CREATE TABLE IF NOT EXISTS c07.TBPRO_MARCA (
	id				SMALLINT		UNSIGNED						NOT NULL,
	nome			varchar(50)										NOT NULL,
	id_empresa		SMALLINT		UNSIGNED								,
	id_distribuidor	SMALLINT		UNSIGNED								,
	ativo			boolean											NOT NULL,
	id_ult_ativacao	int				UNSIGNED						NOT NULL,
	id_res_adicao	int				UNSIGNED						NOT NULL,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_empresa) REFERENCES c07.TBPRO_MAR_EMPRESA(id),
	FOREIGN KEY(id_distribuidor)	REFERENCES c07.TBPRO_MAR_DISTRIBUIDOR(id),
	FOREIGN KEY(id_ult_ativacao) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_res_adicao) REFERENCES c07.TBUSUARIO(id),
	UNIQUE(nome)
);

-- Criando Tabela Produto

CREATE TABLE IF NOT EXISTS c07.TBPRODUTO (
	codigo			INT				UNSIGNED						NOT NULL,
	descricao		VARCHAR(40)												,
	id_marca		SMALLINT		UNSIGNED						NOT NULL,
	unidade			VARCHAR(6)												,
	loja_est		DOUBLE											NOT NULL,
	custo			DOUBLE											NOT NULL,
	venda			DOUBLE											NOT NULL,
	dt_ult_entrada	DATE													,
	dt_ult_preco	DATE													,
	dt_ult_saida	DATE													,
	id_res_cadastro	int				UNSIGNED						NOT NULL,
	dt_cadastro		TIMESTAMP										NOT NULL,
	ativo			BOOLEAN											NOT NULL,
	id_ult_ativacao	int				UNSIGNED						NOT NULL,
	PRIMARY KEY(codigo),
	UNIQUE(descricao)
);

-- Criando Tabela Produtos Pedido

CREATE TABLE IF NOT EXISTS c07.TBPRO_PEDIDO (
	id				INT				UNSIGNED	AUTO_INCREMENT		NOT NULL,
	id_codigo		INT				UNSIGNED						NOT NULL,
	id_responsavel	int				UNSIGNED						NOT NULL,
	data_pedido		TIMESTAMP												,
	quantidade		INT				UNSIGNED						NOT NULL,
	id_res_checagem	int				UNSIGNED								,
	dt_checagem		TIMESTAMP												,
	url_recibo		VARCHAR(255)											,
	
	PRIMARY KEY(id),
	FOREIGN KEY(id_codigo) REFERENCES c07.TBPRODUTO(codigo),
	FOREIGN KEY(id_responsavel) REFERENCES c07.TBUSUARIO(id),
	FOREIGN KEY(id_res_checagem) REFERENCES c07.TBUSUARIO(id),
	UNIQUE(data_pedido)
);

-- 										Garantindo Inserções

-- Inserindo mais Cargos

INSERT INTO c07.TBCARGO(cargo, ativo, id_res_adicao, id_ult_ativacao) VALUES
('Gerente Geral', true, 3, 3),
('Gerente 1', false, 3, 3),
('Gerente 2', true, 3, 3),
('Gerente 3', true, 3, 3),
('Comprador 1', true, 3, 3),
('Comprador 2', true, 3, 3),
('Comprador 3', true, 3, 3),
('Operador', true, 3, 3),
('Repositor', true, 3, 3),
('Fiscal', true, 3, 3);

-- Inserindo Nivel acesso
INSERT INTO c07.TBNIVEL_ACESSO (acesso, ativo, id_res_adicao, id_ult_ativacao) VALUES
('Gerente Geral', true, 3, 3),
('Gerente 1', false, 3, 3),
('Gerente 2', true, 3, 3),
('Gerente 3', true, 3, 3),
('Gerenete-Comprador', true, 3, 3),
('Comprador 1', true, 3, 3),
('Comprador 2', true, 3, 3),
('Comprador 3', true, 3, 3),
('Operador', true, 3, 3),
('Repositor', true, 3, 3),
('Fiscal', true, 3, 3);

-- Inserindo funcionários

INSERT INTO c07.TBUSUARIO(id, nome, nome_sistema, senha, email, data_update, data_nascimento, ativo, id_cargo, id_nivl_acesso, id_res_adicao, id_ult_ativacao) VALUES
(4, 'João Silva Santos', 'João Silva', '3131232', 'joao@gmail.com', current_timestamp(), '1980-5-20', true, 3, 3, 3, 3),
(5, 'Maria Oliveira Costa', 'Maria Oliveira', '3131233', 'maria@gmail.com', current_timestamp(), '1992-8-15', true, 4, 4, 3, 3),
(6, 'Carlos Eduardo Souza', 'Carlos Souza', '3131234', 'carlos@gmail.com', current_timestamp(), '1985-2-10', true, 5, 5, 3, 3),
(7, 'Ana Paula Ferreira', 'Ana Ferreira', '3131235', 'ana@gmail.com', current_timestamp(), '1990-11-25', true, 6, 6, 3, 3),
(8, 'Lucas Henrique Lima', 'Lucas Lima', '3131236', 'lucas@gmail.com', current_timestamp(), '1995-6-18', true, 7, 7, 3, 3),
(9, 'Fernanda Alves Rocha', 'Fernanda Alves', '3131237', 'fernanda@gmail.com', current_timestamp(), '1988-4-7', true, 8, 8, 3, 3),
(10, 'Rafael Martins Costa', 'Rafael Martins', '3131238', 'rafael@gmail.com', current_timestamp(), '1978-9-30', true, 9, 9, 3, 3),
(11, 'Juliana Mendes Silva', 'Juliana Mendes', '3131239', 'juliana@gmail.com', current_timestamp(), '1993-12-3', true, 10, 10, 3, 3),
(12, 'Marcos Vinicius Pereira', 'Marcos Pereira', '3131240', 'marcos@gmail.com', current_timestamp(), '1982-7-22', true, 11, 11, 3, 3),
(13, 'Carlos Inácio Silva', 'Carlos Inacio', '4511237', 'carlosinacio@gmail.com', current_timestamp(), '1999-4-14', true, 12, 12, 3, 3),
(14, 'Fernanda Kippler', 'Fernanda Kippler', '875145', 'kippler@gmail.com', current_timestamp(), '2000-8-7', true, 12, 12, 3, 3);

-- Associando usuario remoto

INSERT INTO c07.TBUSU_REMOTO (id, ip_remoto) VALUES
(1, '192.168.120.24'),
(2, '192.168.120.25'),
(3, '192.168.119.23'),
(4, '192.168.119.85'),
(5, '192.168.119.86');

-- Associando usuario presencial
INSERT INTO c07.TBUSU_PRESENCIAL (id, ip_local) VALUES
(6, '192.168.200.55'),
(7, '192.168.200.56'),
(8, '192.168.200.57'),
(9, '192.168.200.58'),
(10, '192.168.200.59');
 
-- Inserindo Departamento

INSERT INTO c07.TBDEPARTAMENTO(departamento, codigo, ativo, id_ult_ativacao, id_res_adicao) VALUES
('PRODUTOS EM GERAL', 1002, TRUE, 3, 3),
('PADARIA', 584001, TRUE, 3, 3),
('HORT-FRUTI', 631001, TRUE, 3, 3),
('LIMPEZA', 701001, TRUE, 3, 3),
('USO E CONSUMO', 1313003, TRUE, 3, 3),
('FRENTE DE CAIXA', 1313007, TRUE, 3, 3),
('HIGIENE', 1313010, TRUE, 3, 3),
('AÇOUGUE', 1313011, TRUE, 3, 3),
('BEBIDAS', 1313013, TRUE, 3, 3),
('BAZAR', 1313014, FALSE, 3, 3),
('FRIOS', 1313020, TRUE, 3, 3),
('MERCEARIA PESADO', 1313022, TRUE, 3, 3),
('MERCEARIA MOLHO', 1313023, TRUE, 3, 3),
('MERCEARIA BOMBONIERE', 1313024, FALSE, 3, 3),
('FRIOS GELADEIRAS', 1313025, TRUE, 3, 3),
('PADARIA (FRIOS)', 1313027, TRUE, 3, 3),
('CIGARRO', 1313028, FALSE, 3, 3),
('OVOS', 1313029, TRUE, 3, 3),
('PADARIA INSUMOS', 1313030, TRUE, 3, 3),
('MERCEARIA KG', 1313031, TRUE, 3, 3);

-- Inserindo Grupos

INSERT INTO c07.TBGRUPO(grupo, codigo, ativo, id_ult_ativacao, id_res_adicao) VALUES
('FRIOS/CONG', 1, TRUE, 3, 3),
('SUPERMERC', 3, TRUE, 3, 3),
('CARNE BOVINA', 4, TRUE, 3, 3),
('CARNE SUINA', 5, TRUE, 3, 3),
('IOGURTE', 6, TRUE, 3, 3),
('SORVETE', 7, TRUE, 3, 3),
('MACARRAO', 8, TRUE, 3, 3),
('HIG PESSOAL', 11, TRUE, 3, 3),
('BOMBONIERE', 12, TRUE, 3, 3),
('PERFUMARIA', 13, TRUE, 3, 3),
('BEB QUENTES', 14, TRUE, 3, 3),
('SANDALIAS', 15, TRUE, 3, 3),
('CESTA BASICA', 16, TRUE, 3, 3),
('UTILIDADES', 17, TRUE, 3, 3),
('CIGARRO', 18, TRUE, 3, 3),
('PEIXES', 19, TRUE, 3, 3),
('PAPELARIA', 20, TRUE, 3, 3),
('PADARIA EMBALAGENS', 21, TRUE, 3, 3),
('CERVEJAS', 22, TRUE, 3, 3),
('REFRIGERANTES', 23, TRUE, 3, 3);

-- Inserindo Familia

INSERT INTO c07.TBFAMILIA(familia, id_retguarda, ativo, id_res_adicao, id_ult_ativacao) VALUES
('SHAMP SEDA', 2, true, 3, 3),
('COND SEDA', 3, true, 3, 3),
('MACARRAO GALO', 5, true, 3, 3),
('COND DOCE 190M/200ML', 6, true, 3, 3),
('SHAMP DOVE 190ML/200ML', 7, true, 3, 3),
('SHAMP PALMOLIVE', 8, true, 3, 3),
('SHAMP ELSEVE 200ML', 9, true, 3, 3),
('COND ELSEVE', 10, true, 3, 3),
('PITSTOP', 11, true, 3, 3),
('VINHO ALMADEN 750ML', 12, true, 3, 3),
('ABSORVENTE MILI SECA/SUAVE C/8', 13, 1, 3, 3);

-- Inserindo relacionamento TBUSU_RESPONSAVEL

INSERT INTO c07.TBUSU_RESPONSAVEL(id_usuario, id_departamento, id_grupo, id_familia) VALUES
(4,  1, 20, 1),
(5,  2, 17, 2),
(6,  8, 18, 3),
(7,  3, 16, 4),
(8,  9, 5, 5),
(9,  7, 13, 6),
(10, 11, 7, 7),
(11,  4, 19, 8),
(12,  5, 4, 9),
(13,  6, 8, 10);

-- Inserindo Empresas

INSERT INTO c07.TBPRO_MAR_EMPRESA(empresa, ativo, id_ult_ativacao, id_res_adicao) VALUES
('Unilever', TRUE, 3, 3),
('Nestle', TRUE, 3, 3),
('Procter & Gamble', TRUE, 3, 3),
('Coca-Cola', TRUE, 3, 3),
('PepsiCo', TRUE, 3, 3),
('Ambev', TRUE, 3, 3),
('Colgate-Palmolive', TRUE, 3, 3),
('Johnson & Johnson', TRUE, 3, 3),
('BRF', FALSE, 3, 3),
('JBS', TRUE, 3, 3);

-- Inserindo Distribuidores

INSERT INTO c07.TBPRO_MAR_DISTRIBUIDOR(distribuidor, ativo, id_res_adicao, id_ult_ativacao) VALUES
('Distribuidora Minas Sul', TRUE, 3, 3),
('Atacado Bom Preco', TRUE, 3, 3),
('Distribuidora Central', TRUE, 3, 3),
('Comercial Vale Verde', TRUE, 3, 3),
('Distribuidora Nova Era', TRUE, 3, 3),
('Atacado Sao Lucas', TRUE, 3, 3),
('Distribuidora Imperial', TRUE, 3, 3),
('Comercial Dois Irmaos', TRUE, 3, 3),
('Distribuidora Horizonte', FALSE, 3, 3),
('Atacado Brasil Mix', TRUE, 3, 3);

-- Inserindo Marcas

INSERT INTO c07.TBPRO_MARCA(id, nome, id_empresa, id_distribuidor, ativo, id_ult_ativacao, id_res_adicao) VALUES
(1, 'BrilhoMax', 1, 1, TRUE,  3, 3),
(2, 'DoceVida', 2, 2, TRUE,  3, 3),
(3, 'LimpaBem', 3, 3, TRUE,  3, 3),
(4, 'Refresca', 4, 4, TRUE,  3, 3),
(5, 'NutriMais',  5, 5, TRUE,  3, 3),
(6, 'Cervejaria Real', 6, 6, TRUE,  3, 3),
(7, 'Higienix',  7, 7, TRUE,  3, 3),
(8, 'VidaPlena', 8, 8, TRUE,  3, 3),
(9, 'CampoNobre', 9, 9, FALSE, 3, 3),
(10, 'SaborMais', 10, 10, TRUE, 3, 3);

-- Inserindo Produtos

INSERT INTO c07.TBPRODUTO(codigo, descricao, id_marca, unidade, loja_est, custo, venda, dt_ult_entrada, dt_ult_preco, dt_ult_saida, id_res_cadastro,
    dt_cadastro, ativo, id_ult_ativacao) VALUES
(22, 'ARROZ TIPO 1 5KG', 24,  'UN',  150, 18.50, 24.99, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(23, 'FEIJAO CARIOCA 1KG', 64,  'UN',  200,  5.20,  7.49, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(24, 'ACUCAR CRISTAL 5KG', 24,  'UN',   80, 15.00, 19.90, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(25, 'OLEO DE SOJA 900ML', 189,  'UN',  300,  5.10,  7.29, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(26, 'MACARRAO ESPAGUETE 500G',360,  'UN',  180,  2.80,  4.49, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(27, 'FARINHA DE TRIGO 1KG',354,  'UN',  120,  4.30,  6.29, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(28, 'LEITE INTEGRAL 1L',  75,  'UN',  250,  4.20,  5.99, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(29, 'CAFE TORRADO 500G', 363,  'UN',  100, 12.50, 16.90, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(30, 'FUBA MIMOSO 1KG',  461,  'UN',   90,  3.20,  4.79, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(31, 'BISCOITO MAISENA 350G', 357,  'UN',  160,  3.50,  5.49, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3),
(32, 'Bolacha', 357,  'UN',  542,  4.50,  5.49, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 3, CURRENT_TIMESTAMP, TRUE, 3);

-- Inserindo Pedidos
INSERT INTO c07.TBPRO_PEDIDO (id_codigo, id_responsavel, data_pedido, quantidade, id_res_checagem, dt_checagem, url_recibo) VALUES
(22, 1, '2026-10-10 15:36:00', 5, 1, '2026-10-11 15:36:00', NULL),
(23, 2, '2026-10-11 15:36:00', 10, 2, '2026-10-12 15:36:00', NULL),
(24, 3, '2026-10-12 15:36:00', 3, 3, '2026-10-13 15:36:00', NULL),
(25, 1, '2026-10-13 15:36:00', 15, 3, NULL, NULL),
(26, 2, '2026-10-14 15:36:00', 8, 1, '2026-10-15 15:36:00', NULL),
(22, 3, '2026-10-15 15:36:00', 12, 2, '2026-10-16 15:36:00', NULL),
(27, 1, '2026-10-16 15:36:00', 6, 3, NULL, NULL),
(28, 2, '2026-10-17 15:36:00', 20, 3, '2026-10-18 15:36:00', NULL),
(23, 3, '2026-10-18 15:36:00', 4, 1, '2026-10-19 15:36:00', NULL),
(29, 1, '2026-10-19 15:36:00', 7, 3, NULL, NULL),
(30, 2, '2026-10-20 15:36:00', 9, 2, '2026-10-21 15:36:00', NULL),
(25, 3, '2026-10-21 15:36:00', 5, 3, '2026-10-22 15:36:00', NULL),
(31, 1, '2026-10-22 15:36:00', 2, 3, NULL, NULL),
(26, 2, '2026-10-23 15:36:00', 18, 1, '2026-10-24 15:36:00', NULL),
(22, 3, '2026-10-24 15:36:00', 3, 3, NULL, NULL),
(28, 1, '2026-10-25 15:36:00', 11, 2, '2026-10-26 15:36:00', NULL),
(24, 2, '2026-10-26 15:36:00', 6, NULL, NULL, NULL),
(29, 3, '2026-10-27 15:36:00', 14, 3, '2026-10-28 15:36:00', NULL),
(30, 1, '2026-10-28 15:36:00', 4, NULL, NULL, NULL),
(31, 2, '2026-10-29 15:36:00', 8, 1, '2026-10-30 15:36:00', NULL);

-- Mostra todos os produtos que tem pedidos e quantidade de pedidos, e também mostra todos os produtos que não tem pedido
SELECT PR.codigo, PR.descricao AS produto, IF(COUNT(P.id) = 0, 'Nenhum pedido feito', COUNT(P.id)) AS status_pedidos
FROM TBPRODUTO PR LEFT JOIN TBPRO_PEDIDO P ON PR.codigo = P.id_codigo GROUP BY PR.codigo, PR.descricao
ORDER BY COUNT(P.id) DESC, PR.descricao ASC;


-- Criação de usuarios e privilegios 
CREATE USER IF NOT EXISTS 'LUAN'@'c07' IDENTIFIED BY '0138';
CREATE USER IF NOT EXISTS 'IGOR'@'%' IDENTIFIED BY '8023';
CREATE USER IF NOT EXISTS 'JONAS'@'%' IDENTIFIED BY '1234';
CREATE USER IF NOT EXISTS 'FELIPE'@'%' IDENTIFIED BY '4321';

-- Dando permissao
GRANT ALL PRIVILEGES ON c07.* TO 'LUAN'@'c07';
GRANT SELECT, UPDATE ON c07.* TO 'IGOR'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'JONAS'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'FELIPE'@'%';

-- Aplicar as alterações
FLUSH PRIVILEGES;

-- Revogando acesso
REVOKE DELETE ON c07.* FROM 'LUAN'@'c07';
REVOKE UPDATE ON c07.* FROM 'IGOR'@'%';

-- Aplicar as alterações
FLUSH PRIVILEGES;

-- Mostrando perimissões
SHOW GRANTS FOR 'LUAN'@'c07';

-- Criando role 
CREATE ROLE IF NOT EXISTS 'ASSISTENTS_GROUP';
GRANT SELECT, UPDATE ON C07.* TO 'ASSISTENTS_GROUP';
CREATE USER IF NOT EXISTS 'LUAN'@'%' IDENTIFIED BY '0138';
CREATE ROLE IF NOT EXISTS 'OWNER_GROUP';
GRANT SELECT, UPDATE ON c07.* TO 'ASSISTENTS_GROUP';



GRANT ALL PRIVILEGES ON *.* TO 'OWNER_GROUP';
DROP USER IF EXISTS 'JONAS'@'%', 'FELIPE'@'%';
CREATE USER IF NOT EXISTS 'JONAS'@'%' IDENTIFIED BY '1234';
CREATE USER IF NOT EXISTS 'FELIPE'@'%' IDENTIFIED BY '4321';
CREATE USER IF NOT EXISTS 'ADMIN'@'%' IDENTIFIED BY '1234';
GRANT 'OWNER_GROUP' TO 'ADMIN'@'%';
SET DEFAULT ROLE 'OWNER_GROUP' TO 'ADMIN'@'%';

-- Criando procedures

DROP PROCEDURE IF EXISTS c07.SP_GETUSUARIOS;
DROP PROCEDURE IF EXISTS c07.SP_GETUSUARIOSBYID;

DELIMITER $$
CREATE PROCEDURE c07.SP_GETUSUARIOS()
BEGIN 
	SELECT USR.*, CRG.*, NVA.*
	FROM c07.TBUSUARIO 	USR
	JOIN c07.TBCARGO 		CRG ON USR.id_cargo = CRG.id
	JOIN c07.TBNIVEL_ACESSO NVA ON USR.id_nivl_acesso = NVA.id
	WHERE USR.ativo = true;
END$$
DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_GETUSUARIOSBYID(p_id INT)
BEGIN 
	SELECT USR.*, CRG.*, NVA.*
	FROM c07.TBUSUARIO 	USR
	JOIN c07.TBCARGO 		CRG ON USR.id_cargo = CRG.id
	JOIN c07.TBNIVEL_ACESSO NVA ON USR.id_nivl_acesso = NVA.id
	WHERE USR.ativo = true
	AND USR.id = p_id;
END$$

DELIMITER ;

-- Chamando procedures
CALL c07.SP_GETUSUARIOS();
CALL c07.SP_GETUSUARIOSBYID(1);

-- Criando uma function 
DELIMITER $$
DROP FUNCTION IF EXISTS c07.CALCULA_LUCRO_TOTAL$$
CREATE FUNCTION c07.CALCULA_LUCRO_TOTAL(CUSTO DOUBLE, VENDA DOUBLE, QUANTIDADE DOUBLE) 
RETURNS DOUBLE
DETERMINISTIC
BEGIN 
	RETURN (VENDA - CUSTO) * QUANTIDADE;
END$$
DELIMITER ;

SELECT c07.CALCULA_LUCRO_TOTAL(15.50,30.00,1.00) AS LUCRO_DA_VENDA;
DROP FUNCTION IF EXISTS c07.CALCULA_LUCRO_TOTAL;

-- Criando View 
CREATE OR REPLACE VIEW c07.VIEWGRUPO AS SELECT * FROM c07.TBGRUPO;
SELECT * FROM c07.VIEWGRUPO;

CREATE OR REPLACE VIEW c07.VIEWGRUPO AS SELECT GRP.grupo FROM c07.TBGRUPO GRP;

-- Trigger
DELIMITER $$
CREATE TRIGGER c07.TRGATUALIZA_DATA_USUARIO BEFORE UPDATE ON c07.TBUSUARIO 
FOR EACH ROW 
BEGIN
	SET NEW.data_update = NOW();
END$$
DELIMITER ;

DROP VIEW IF EXISTS c07.VIEWGRUPO;