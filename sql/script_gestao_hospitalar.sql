create database gestao_hospitalar;
use gestao_hospitalar;

-- criação das tabelas ---------------
create table setor_hospital (
    id_setor int auto_increment primary key,
    nome_setor varchar(255) not null,
    bloco_pavilhao varchar(50),
    responsavel_setor varchar(100)
);

create table classe_residuo (
    id_classe int auto_increment primary key,
    grupo_anvisa varchar(10) not null,
    descricao_classe varchar(500),
    nivel_periculosidade varchar(20),
    tempo_max_armazenamento_horas int,
    constraint chk_grupo_anvisa check (grupo_anvisa in ('Grupo A', 'Grupo B', 'Grupo C', 'Grupo D', 'Grupo E'))
);

create table empresa_destino (
    id_empresa int auto_increment primary key,
    razao_social varchar(150) not null,
    cnpj varchar(18) unique not null,
    licenca_ambiental varchar(100),
    tipo_tratamento varchar(100)
);

create table funcionario (
    id_funcionario int auto_increment primary key,
    id_setor int not null,
    nome varchar(100) not null,
    cpf varchar(14) unique not null,
    cargo varchar(50)
);

create table coleta_residuo (
    id_coleta int auto_increment primary key,
    id_setor int not null,
    id_classe int not null,
    id_funcionario int not null,
    peso_kg decimal(8,2) not null,
    data_hora_registro datetime not null,
    status_armazenamento varchar(30) default 'Em Depósito Temporário'
);

create table descarte_final (
    id_descarte int auto_increment primary key,
    id_coleta int unique not null,
    id_empresa int not null,
    data_hora_descarte datetime not null,
    numero_certificado_mtr varchar(100) unique not null,
    custo_tratamento decimal(10,2)
);

-- adição de chaves estrangeiras ---------------

alter table funcionario
    add constraint fk_funcionario_setor 
    foreign key (id_setor) references setor_hospital(id_setor);

alter table coleta_residuo
    add constraint fk_coleta_setor 
    foreign key (id_setor) references setor_hospital(id_setor),
    add constraint fk_coleta_classe 
    foreign key (id_classe) references classe_residuo(id_classe),
    add constraint fk_coleta_funcionario 
    foreign key (id_funcionario) references funcionario(id_funcionario);

alter table descarte_final
    add constraint fk_descarte_coleta 
    foreign key (id_coleta) references coleta_residuo(id_coleta),
    add constraint fk_descarte_empresa 
    foreign key (id_empresa) references empresa_destino(id_empresa);
    
-- populando tabelas ---------------

insert into setor_hospital (nome_setor, bloco_pavilhao, responsavel_setor) values
('UTI Neonatal', 'Bloco A - 2º Andar', 'Dra. Maria Silva'),
('Centro Cirúrgico', 'Bloco B - 1º Andar', 'Dr. Carlos Eduardo'),
('Laboratório de Análises', 'Bloco A - Térreo', 'Dra. Ana Paula'),
('Pronto Atendimento', 'Bloco C - Térreo', 'Enf. Roberto Souza');

insert into classe_residuo (grupo_anvisa, descricao_classe, nivel_periculosidade, tempo_max_armazenamento_horas) values
('Grupo A', 'Resíduos Infectantes / Biológicos (sangue, tecidos, luvas contagiadas)', 'Alto', 24),
('Grupo B', 'Resíduos Químicos / Farmacêuticos (medicamentos vencidos, reagentes)', 'Médio', 48),
('Grupo C', 'Rejeitos Radioativos (exames de medicina nuclear)', 'Crítico', 12),
('Grupo D', 'Resíduos Comuns / Recicláveis (papelão, embalagens limpas)', 'Baixo', 72),
('Grupo E', 'Perfurocortantes (agulhas, ampolas de vidro, bisturis)', 'Alto', 24);

insert into empresa_destino (razao_social, cnpj, licenca_ambiental, tipo_tratamento) values
('EcoTrata Gestão Ambiental Ltda', '12.345.678/0001-90', 'LA-2024-0089', 'Autoclavagem e Incineração'),
('Recicla Hospitalar S.A.', '98.765.432/0001-10', 'LA-2023-0145', 'Reciclagem e Aterro Sanitário');

insert into funcionario (id_setor, nome, cpf, cargo) values
(1, 'João Pedro Santos', '111.222.333-44', 'Técnico de Enfermagem'),
(2, 'Fernanda Lima', '222.333.444-55', 'Auxiliar de Serviços Gerais'),
(3, 'Lucas Mendes', '333.444.555-66', 'Biomédico');

insert into coleta_residuo (id_setor, id_classe, id_funcionario, peso_kg, data_hora_registro, status_armazenamento) values
(2, 1, 2, 45.50, '2026-03-01 08:30:00', 'Processado'),
(2, 5, 2, 12.30, '2026-03-01 09:00:00', 'Processado'),
(1, 1, 1, 18.20, '2026-03-01 10:15:00', 'Processado'),
(3, 2, 3, 8.75, '2026-03-02 11:00:00', 'Em Depósito Temporário'),
(4, 4, 2, 85.00, '2026-03-02 14:20:00', 'Processado');

insert into descarte_final (id_coleta, id_empresa, data_hora_descarte, numero_certificado_mtr, custo_tratamento) values
(1, 1, '2026-03-01 16:00:00', 'MTR-2026-0001', 350.00),
(2, 1, '2026-03-01 16:00:00', 'MTR-2026-0002', 180.00),
(3, 1, '2026-03-01 17:30:00', 'MTR-2026-0003', 210.00),
(5, 2, '2026-03-02 18:00:00', 'MTR-2026-0004', 120.00);

-- criando consultas (querys) ---------------

-- Total de Peso de Resíduos por Grupo ANVISA

select 
    c.grupo_anvisa,
    c.nivel_periculosidade,
    count(r.id_coleta) as total_coletas,
    sum(r.peso_kg) as total_peso_kg
from classe_residuo c
left join coleta_residuo r on c.id_classe = r.id_classe
group by c.id_classe, c.grupo_anvisa, c.nivel_periculosidade
order by total_peso_kg desc;

-- Rastreabilidade Completa (Do Setor ao Certificado MTR)

select 
    r.id_coleta,
    s.nome_setor,
    c.grupo_anvisa,
    f.nome as funcionario_responsavel,
    r.peso_kg,
    e.razao_social as empresa_destinataria,
    d.numero_certificado_mtr,
    d.custo_tratamento
from coleta_residuo r
join setor_hospital s on r.id_setor = s.id_setor
join classe_residuo c on r.id_classe = c.id_classe
join funcionario f on r.id_funcionario = f.id_funcionario
left join descarte_final d on r.id_coleta = d.id_coleta
left join empresa_destino e on d.id_empresa = e.id_empresa;

-- Custo Total por Empresa Destinátaria

select 
    e.razao_social,
    e.tipo_tratamento,
    count(d.id_descarte) as quantidade_descartes,
    sum(d.custo_tratamento) as custo_total_reais
from empresa_destino e
join descarte_final d on e.id_empresa = d.id_empresa
group by e.id_empresa, e.razao_social, e.tipo_tratamento;

-- Criação de View Relatorio final: 

create view vw_rastreabilidade_residuos as
select 
    r.id_coleta,
    s.nome_setor,
    c.grupo_anvisa,
    f.nome as funcionario_responsavel,
    r.peso_kg,
    r.data_hora_registro,
    r.status_armazenamento,
    d.numero_certificado_mtr,
    e.razao_social as empresa_destino,
    d.custo_tratamento
from coleta_residuo r
join setor_hospital s on r.id_setor = s.id_setor
join classe_residuo c on r.id_classe = c.id_classe
join funcionario f on r.id_funcionario = f.id_funcionario
left join descarte_final d on r.id_coleta = d.id_coleta
left join empresa_destino e on d.id_empresa = e.id_empresa;

select * from vw_rastreabilidade_residuos;

-- controle de acesso e segurança

-- 1. Perfil Enfermagem (Operacional): Registra e consulta apenas coletas
CREATE USER IF NOT EXISTS 'usr_enfermagem'@'%' IDENTIFIED BY 'SenhaEnfermagem2026!';
GRANT INSERT, SELECT ON gestao_hospitalar.coleta_residuo TO 'usr_enfermagem'@'%';

-- 2. Perfil Gestão Hospitalar: Acesso a relatórios analíticos e visões
CREATE USER IF NOT EXISTS 'usr_gestao'@'%' IDENTIFIED BY 'SenhaGestao2026!';
GRANT SELECT ON gestao_hospitalar.vw_rastreabilidade_residuos TO 'usr_gestao'@'%';

-- 3. Perfil Fiscalização / Auditores: Leitura de certificados MTR e descartes
CREATE USER IF NOT EXISTS 'usr_fiscalizacao'@'%' IDENTIFIED BY 'SenhaFiscal2026!';
GRANT SELECT ON gestao_hospitalar.descarte_final TO 'usr_fiscalizacao'@'%';
GRANT SELECT ON gestao_hospitalar.empresa_destino TO 'usr_fiscalizacao'@'%';

-- 4. Perfil Administrador de Banco de Dados (DBA): Gestão total e privilégios
CREATE USER IF NOT EXISTS 'usr_dba'@'localhost' IDENTIFIED BY 'SenhaDba2026!';
GRANT ALL PRIVILEGES ON gestao_hospitalar.* TO 'usr_dba'@'localhost' WITH GRANT OPTION;

-- Aplica as permissões no servidor MySQL
FLUSH PRIVILEGES;