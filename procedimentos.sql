CREATE OR REPLACE FUNCTION VALIDA_CPF_CNPJ(V_CPF_CNPJ VARCHAR2) RETURN BOOLEAN IS
  e_CPF_CNPJ_null exception;
  e_cpf_cnpj_tama exception;
  TYPE ARRAY_DV IS VARRAY(2) OF PLS_INTEGER;
  V_ARRAY_DV ARRAY_DV := ARRAY_DV(0, 0);
  CPF_DIGIT  CONSTANT PLS_INTEGER := 11;
  CNPJ_DIGIT CONSTANT PLS_INTEGER := 14; 
  IS_CPF       BOOLEAN;
  IS_CNPJ      BOOLEAN;
  V_CPF_NUMBER VARCHAR2(20);
  TOTAL        NUMBER := 0;
  COEFICIENTE  NUMBER := 0;
  DV1    NUMBER := 0;
  DV2    NUMBER := 0;
  DIGITO NUMBER := 0;
  J      INTEGER;
  I      INTEGER;

BEGIN
  --
  IF V_CPF_CNPJ IS NULL THEN
    raise e_CPF_CNPJ_null;
  END IF; 
  --
  V_CPF_NUMBER := REGEXP_REPLACE(V_CPF_CNPJ, '[^0-9]'); 
  --
  if LENGTH(V_CPF_NUMBER) > 14 then
    raise e_cpf_cnpj_tama;
  end if; 
  --
  IS_CPF := (LENGTH(V_CPF_NUMBER) = CPF_DIGIT); 


  IS_CNPJ := (LENGTH(V_CPF_NUMBER) = CNPJ_DIGIT);

  IF (IS_CPF OR IS_CNPJ) THEN
    TOTAL := 0;
  ELSE
    RETURN FALSE;
  END IF;

  DV1 := TO_NUMBER(SUBSTR(V_CPF_NUMBER, LENGTH(V_CPF_NUMBER) - 1, 1));
  DV2 := TO_NUMBER(SUBSTR(V_CPF_NUMBER, LENGTH(V_CPF_NUMBER), 1)); 

  V_ARRAY_DV(1) := 0;
  V_ARRAY_DV(2) := 0; 

  FOR J IN 1 .. 2
  LOOP
    TOTAL := 0;
    COEFICIENTE := 2;

    FOR I IN REVERSE 1 .. ((LENGTH(V_CPF_NUMBER) - 3) + J)
    LOOP
      DIGITO := TO_NUMBER(SUBSTR(V_CPF_NUMBER, I, 1));
      TOTAL := TOTAL + (DIGITO * COEFICIENTE);   

      COEFICIENTE := COEFICIENTE + 1;
      IF (COEFICIENTE > 9) AND IS_CNPJ THEN
        COEFICIENTE := 2;
      END IF;   

    END LOOP; --for i

    V_ARRAY_DV(J) := 11 - MOD(TOTAL, 11);
    IF (V_ARRAY_DV(J) >= 10) THEN
      V_ARRAY_DV(J) := 0;
    END IF; 

  END LOOP;

  RETURN(DV1 = V_ARRAY_DV(1)) AND(DV2 = V_ARRAY_DV(2)); 

exception
  when e_CPF_CNPJ_null then
    raise_application_error(-20000, 'CPF ou CNPJ esta vazio.');
  when e_cpf_cnpj_tama then
    raise_application_error(-20000, 'Ultrapasso o limite de caracteres.');
  when others then
    raise_application_error(-20000, 'email_valido: '||sqlerrm);
END VALIDA_CPF_CNPJ;
/
sho err
--
create or replace function email_valido (p_email in  varchar2) return boolean is
  --
  v_email        varchar2(200);
  e_email_null   exception;
  e_email_tama   exception;
  -- expressão regular para validar e-mail
  v_pattern      varchar2(200) := '^[a-z]+[\.\_\-[a-z0-9]+]*[a-z0-9]@[a-z0-9]+\-?[a-z0-9]{1,63}\.?[a-z0-9]{0,6}\.?[a-z0-9]{0,6}\.[a-z]{0,6}$';
begin
  --
  if p_email is null then
    raise e_email_null;
  end if;
  --
  if LENGTH(p_email) > 100 then
    raise e_email_tama;
  end if; 
  v_email := lower(p_email);
  if  not owa_pattern.match (v_email,v_pattern) then
      return false;
  end if;
  if  instr(p_email,'..')  >  0  then
      return false ;
  end if;
  --
  return true;
  --
exception
  when e_email_null then
    raise_application_error(-20000, 'email esta vazio.');
  when e_email_tama then
    raise_application_error(-20000, 'Limite para tamanho do e-mail: 100 caracteres.');
  when others then
    raise_application_error(-20000, 'email_valido: '||sqlerrm);
end email_valido;
/
sho err
create or replace procedure insere_restaurante(p_nome_restaurante in varchar2
                                              ,p_nm_cnpj_rest     in varchar2
                                              ,p_nr_cnpj_rest     in varchar2
                                              ,p_email            in varchar2
                                              ) is
 vn_id_restaurante  number;
 e_nm_rest_null     exception;
 e_cnpj_rest_null   exception;
 e_email_rest_null  exception;
 e_email_invalido   exception;
 e_cnpj_invalido    exception;
begin
  --
  vn_id_restaurante := sq_pr_restaurante.nextval;
  --
  if p_nm_cnpj_rest is null then
    raise e_nm_rest_null;
  end if;
  --
  if p_nr_cnpj_rest is null then
    raise e_cnpj_rest_null;
  elsif not valida_cpf_cnpj(v_cpf_cnpj => p_nr_cnpj_rest) then
    raise e_cnpj_invalido;
  end if;
  --
  if p_email is null then
    raise e_email_rest_null;
  elsif not email_valido(p_email => p_email) then
    raise e_email_invalido;
  end if;
  --
  insert into t_pr_restaurante( id_restaurante 
                              , nm_restaurante 
                              , nr_cnpj_rest   
                              , ds_email     
                              , dt_cadastro)
                       values (vn_id_restaurante
                              ,p_nm_cnpj_rest
                              ,p_nr_cnpj_rest
                              ,p_email
                              ,sysdate );
  --
exception
  when e_cnpj_rest_null then
    raise_application_error(-20000, 'Informe o CNPJ do restaurante.');
  when e_cnpj_invalido then
    raise_application_error(-20000, 'CPF ou CNPJ Invalido.');
  when e_nm_rest_null then
    raise_application_error(-20000, 'Informe o Nome do Restaurante.');
  when e_email_rest_null then
    raise_application_error(-20000, 'Informe um email para contato.');
  when e_email_invalido then
    raise_application_error(-20000, 'O e-mail informado esta invalido.');
  when Dup_Val_On_Index then
    raise_application_error(-20000, 'Registro já inserido.');
  when others then
    raise_application_error(-20000, 'insere_restaurante: '||sqlerrm);
end insere_restaurante;
/
sho err
--
create or replace function cnpj_existe(p_nr_cnpj_rest in varchar2) return boolean is 
vn_count        number;
e_cnpj_null     exception;
e_cnpj_invalido exception;
begin
  --
  if p_nr_cnpj_rest is null then
    raise e_cnpj_null;
  elsif not valida_cpf_cnpj(v_cpf_cnpj => p_nr_cnpj_rest) then
    raise e_cnpj_invalido;
  end if;
  --
  select count(1)
    into vn_count
   from t_pr_restaurante c 
   where c.nr_cnpj_rest = p_nr_cnpj_rest;
  --
  if vn_count > 0 then
    return true;
  else
    return false;
  end if;
  --
exception
  when e_cnpj_invalido then
    raise_application_error(-20000, 'CNPJ Invalido.');
  when e_cnpj_null then
    raise_application_error (-20000, 'CNPJ não foi informado.');
  when others then
    raise_application_error (-20000, 'cnpj_existe: ' || sqlerrm);
end cnpj_existe;
/
sho err
--
create or replace function obtem_id_restaurante(p_nr_cnpj in varchar2) return number is
 vn_id_restaurante number;
 e_cnpj_null       exception;
begin
  --
  if p_nr_cnpj is null then
    raise e_cnpj_null;
  end if;
  --
  select id_restaurante
    into vn_id_restaurante
    from t_pr_restaurante
   where nr_cnpj_rest = p_nr_cnpj;
  --
  return vn_id_restaurante;
  --
exception
  when e_cnpj_null then
    raise_application_error (-20000, 'O CNPJ não foi informado.');
  when no_data_found then
    raise_application_error (-20000, 'Nenhum registro encontrado.');
  when others then
    raise_application_error (-20000, 'obtem_id_restaurante: ' || sqlerrm);
end obtem_id_restaurante;
/
sho err
--
create or replace procedure insere_cliente( p_nm_cliente in varchar2
                                           ,p_nr_cpf     in varchar2
                                           ,p_ds_email   in varchar2) is
  vn_id_cliente  number;
  e_cliente_null exception;
  e_cpf_null     exception;
  e_email_null   exception;
  e_email_inval  exception;
  e_cpf_inval    exception;
begin
  --
  vn_id_cliente := sq_pr_cliente.nextval;
  --
  if p_nm_cliente is null then
    raise e_cliente_null;
  end if;
  --
  if p_nr_cpf is null then
    raise e_cpf_null;
  elsif not valida_cpf_cnpj(v_cpf_cnpj => p_nr_cpf) then
    raise e_cpf_inval;
  end if;
  --
  if p_ds_email is null then
    raise e_email_null;
  elsif not email_valido(p_email => p_ds_email) then
    raise e_email_inval;
  end if;
  --
  insert into t_pr_cliente (id_cliente  
                           ,nm_cliente  
                           ,nr_cpf      
                           ,ds_email    
                           ,dt_cadastro)
                   values ( vn_id_cliente
                           ,p_nm_cliente 
                           ,p_nr_cpf     
                           ,p_ds_email   
                           ,sysdate);

  --
exception
  when e_email_null then
    raise_application_error(-20000, 'Email não pode ser nulo');
  when e_email_inval then
    raise_application_error(-20000, 'O E-mail informado não é válido.');
  when e_cpf_null then
    raise_application_error(-20000, 'Informe o CPF');
  when e_cpf_inval then
    raise_application_error(-20000, 'O CPF esta invalido.');
  when e_cliente_null then
    raise_application_error(-20000, 'Nome do Cliente esta nulo.');
  when Dup_Val_On_Index then
    raise_application_error(-20000, 'Cliente já foi cadastrado.');
  when others then
    raise_application_error(-20000, 'insere_cliente: '||sqlerrm);
end insere_cliente;
/
sho err
--
create or replace function obtem_id_cliente(p_nr_cpf in varchar2) return number is 
 vv_nr_cpf varchar2(20);
 e_cpf_null exception;
begin
  --
  if p_nr_cpf is null then
    raise e_cpf_null;
  end if;
  --
  select id_cliente 
    into vv_nr_cpf
    from T_PR_CLIENTE
   where nr_cpf = p_nr_cpf;
   --
  return vv_nr_cpf;
  --
--
exception
  when e_cpf_null then
    raise_application_error (-20000, 'Inform o CPF;');
  when no_data_found then
    raise_application_error (-20000, 'Cliente não encontrado.');
  when others then
    raise_application_error (-20000, 'obtem_id_cliente: ' || sqlerrm);
end obtem_id_cliente;
--
/ 
sho err
--
create or replace function insere_telefone(p_nr_telefone in number
                                          ,p_nr_ddd      in number
                                          ,p_nr_ddi      in number
                                          ,p_ds_telefone in varchar2) return number is
--
vn_id_telefone number;
--
e_ddd_null    exception;
e_ddi_null    exception;
e_tel_null    exception;
e_tel_ds_null exception;
e_nr_tel      exception;
e_tam_tel     exception;
--
begin
  --
  vn_id_telefone := sq_pr_telefone.nextval;
  --
  if p_nr_ddd is null then
    raise e_ddd_null;
  end if;
  --
  if p_nr_ddi is null then 
    raise e_ddi_null;
  end if;
  --
  if p_ds_telefone is null then 
    raise e_tel_ds_null;
  end if;
  --
  if p_nr_telefone is null then 
    raise e_nr_tel;
  end if;
  --
  if LENGTH(p_nr_telefone) > 9 then 
    raise e_tam_tel;
  end if;
  --
  insert into  t_pr_telefone (id_telefone
                             ,nr_telefone
                             ,nr_ddd     
                             ,nr_ddi     
                             ,ds_telefone)
                      values (vn_id_telefone
                             ,p_nr_telefone
                             ,p_nr_ddd     
                             ,p_nr_ddi     
                             ,upper(p_ds_telefone));
  --
  return vn_id_telefone;
  --
exception
  when e_tam_tel then
    raise_application_error(-20000, 'telefone ultrapassou o tamanho de 9 digitos.');
  when e_nr_tel then
    raise_application_error(-20000, 'O telefone não foi informado.');
  when e_tel_ds_null then
    raise_application_error(-20000, 'Informe a descrição do telefone');
  when e_ddi_null then
    raise_application_error(-20000, 'DDI esta nulo.');
  when e_ddd_null then
    raise_application_error(-20000, 'DDD não foi informado.');
  when others then
    raise_application_error(-20000, 'insere_telefone: '||sqlerrm);
end insere_telefone;
/ 
sho err
--
create or replace procedure insere_cliente_telefone(p_nm_cliente  in varchar2
                                                   ,p_nr_cpf      in varchar2
                                                   ,p_ds_email    in varchar2
                                                   ,p_nr_telefone in number
                                                   ,p_nr_ddd      in number
                                                   ,p_nr_ddi      in number
                                                   ,p_ds_telefone in varchar2) is
  vn_id_cliente  number;
  vn_id_telefone number;
  e_nao_tel      exception;  
  e_nao_cli      exception;
begin
  --
  insere_cliente( p_nm_cliente => p_nm_cliente
                , p_nr_cpf     => p_nr_cpf
                , p_ds_email   => p_ds_email) ;
  --
  vn_id_cliente := obtem_id_cliente(p_nr_cpf => p_nr_cpf); 
  --
  if vn_id_cliente is null then
    raise e_nao_cli;
  end if;
  --
  vn_id_telefone := insere_telefone(p_nr_telefone => p_nr_telefone
                                   ,p_nr_ddd      => p_nr_ddd
                                   ,p_nr_ddi      => p_nr_ddi
                                   ,p_ds_telefone => p_ds_telefone) ;
  --
  if vn_id_telefone is null then
    raise e_nao_tel;
  end if;
  --
  insert into t_pr_tel_cliente(id_cliente
                              ,id_telefone)
                       values(vn_id_cliente
                             ,vn_id_telefone);
  --
exception
  when e_nao_cli then
    raise_application_error(-20000, 'Não foi possível inserir o cliente '||sqlerrm);
  when e_nao_tel then
    raise_application_error(-20000, 'Não foi possível inserir o telefone '||sqlerrm);
  when others then
    raise_application_error(-20000, 'insere_cliente_telefone: '||sqlerrm);
end insere_cliente_telefone;
/
sho err
--
create or replace procedure insere_restaurante_telefone(p_nome_restaurante in varchar2
                                                       ,p_nm_cnpj_rest     in varchar2
                                                       ,p_nr_cnpj_rest     in varchar2
                                                       ,p_email            in varchar2
                                                       ,p_nr_telefone      in number
                                                       ,p_nr_ddd           in number
                                                       ,p_nr_ddi           in number
                                                       ,p_ds_telefone      in varchar2) is 
  vn_id_restaurante number;
  vn_id_telefone    number;
  vrt_tel_rest      t_pr_tel_rest%rowtype;
  e_sem_tel         exception;
  e_sem_rest        exception;
begin
  --
  insere_restaurante(p_nome_restaurante => p_nome_restaurante
                    ,p_nm_cnpj_rest     => p_nm_cnpj_rest
                    ,p_nr_cnpj_rest     => p_nr_cnpj_rest
                    ,p_email            => p_email  );
  --
  vn_id_restaurante := obtem_id_restaurante(p_nr_cnpj => p_nr_cnpj_rest);
  --
  if vn_id_restaurante is null then
    raise e_sem_rest;
  end if;
  --
  vn_id_telefone := insere_telefone(p_nr_telefone => p_nr_telefone
                                   ,p_nr_ddd      => p_nr_ddd
                                   ,p_nr_ddi      => p_nr_ddi
                                   ,p_ds_telefone => p_ds_telefone) ;
  --
  if vn_id_telefone is null then
    raise e_sem_tel;
  end if;
  --
  vrt_tel_rest.id_telefone    := vn_id_telefone;
  vrt_tel_rest.id_restaurante := vn_id_restaurante;
  --
  insert into t_pr_tel_rest values vrt_tel_rest;
  --
exception
  when e_sem_tel then
    raise_application_error(-20000, 'Erro ao inserir o telefone: '||sqlerrm);
  when e_sem_rest then
    raise_application_error(-20000, 'Erro ao inserir o restaurante: '||sqlerrm);
  when others then
    raise_application_error(-20000, 'insere_restaurante_telefone: '||sqlerrm);
end insere_restaurante_telefone;
/
sho err
--
create or replace procedure insere_estado(p_nm_estado in varchar2
                                         ,p_sg_estado in varchar2) is
e_sem_nm      exception;
e_sem_sg      exception;
e_tam_sg      exception;
vn_id_estado  number;
vrt_estado    t_pr_estado%rowtype;
begin
  --
  if p_nm_estado is null then
    raise e_sem_nm;
  end if;
  --
  if p_sg_estado is null then
    raise e_sem_sg;
  elsif LENGTH(p_sg_estado) > 2 or LENGTH(p_sg_estado) < 2  then
    raise e_tam_sg;
  end if;
  --
  vn_id_estado := sq_pr_estado.nextval;
  --
  vrt_estado.id_estado := vn_id_estado;
  vrt_estado.nm_estado := p_nm_estado;
  vrt_estado.sg_estado := upper(p_sg_estado);
  --
  insert into t_pr_estado values vrt_estado;
  --
exception
  when e_sem_sg then
    raise_application_error(-20000, 'A sigla deve ser informada.');
  when e_sem_nm then
    raise_application_error(-20000, 'Não é possível inseri nome do Estado nulo.');
  when e_tam_sg then
    raise_application_error(-20000, 'A silgla deve ter 2 digitos.');
  when Dup_Val_On_Index then
    raise_application_error(-20000, 'Já existe essa sigla');
  when others then
    raise_application_error(-20000, 'insere_estado: '||sqlerrm);
end insere_estado;
/
sho err
--
create or replace function obtem_id_estado(p_sg_estado in varchar2) return number is 
vn_id_estado number;
e_sg_null    exception;
begin
  --
  if p_sg_estado is null then
    raise e_sg_null;
  end if;
  --
  select id_estado
    into vn_id_estado
    from t_pr_estado 
    where sg_estado = p_sg_estado;
  --
  return vn_id_estado;
  --
exception
  when e_sg_null then
    raise_application_error (-20000, 'A sigla deve ser informada.');
  when no_data_found then
    raise_application_error (-20000, 'Estado não encontrado.');
  when others then
    raise_application_error (-20000, 'obtem_id_estado: ' || sqlerrm);
end obtem_id_estado;
/
sho err
--
create or replace function existe_estado(p_sg_estado in varchar2) return boolean is 
vn_count number;
e_sg_null    exception;
e_sg_tam     exception;
begin
  --
  if p_sg_estado is null then
    raise e_sg_null;
  elsif LENGTH(p_sg_estado) > 2 then
    raise e_sg_tam;
  end if;
  --
  select count(1)
    into vn_count
    from t_pr_estado 
    where sg_estado = p_sg_estado;
  --
  if vn_count > 0 then
    return true;
  else
    return false;
  end if;
  --
exception
  when e_sg_tam then
    raise_application_error (-20000, 'O tamanho da sigla é 2.');
  when e_sg_null then
    raise_application_error (-20000, 'A sigla deve ser informada.');
  when others then
    raise_application_error (-20000, 'existe_estado: ' || sqlerrm);
end existe_estado;
/
sho err
--
create or replace procedure insere_cidade(p_sg_estado in varchar2
                                         ,p_nm_estado in varchar2 default null
                                         ,p_nm_cidade in varchar2) is
e_sem_nm_cidade exception;
e_sem_sg        exception;
vrt_cidade      t_pr_cidade%rowtype;                               
begin
  --
  if p_sg_estado is null then
    raise e_sem_sg;
  end if;
  --
  if p_nm_cidade is null then
    raise e_sem_nm_cidade;
  end if;
  --
  vrt_cidade.id_cidade := sq_pr_cidade.nextval;
  --
  if not existe_estado(p_sg_estado => p_sg_estado) and  p_nm_estado is not null then
    --
    insere_estado(p_nm_estado => p_nm_estado
                 ,p_sg_estado => p_sg_estado);
    --
  end if;
  --
  vrt_cidade.id_estado := obtem_id_estado(p_sg_estado => p_sg_estado);
  vrt_cidade.nm_cidade := upper(p_nm_cidade);
  --
  insert into t_pr_cidade values vrt_cidade; 
  --
exception
  when e_sem_nm_cidade then
    raise_application_error(-20000, 'O nome da cidade esta nulo.');
  when e_sem_sg then
    raise_application_error(-20000, 'A sigla não foi informada.');
  when others then
    raise_application_error(-20000, 'insere_cidade: '||sqlerrm);
end insere_cidade;
/
sho err
--
create or replace function obtem_id_cidade(p_nm_cidade in varchar2
                                          ,p_sg_estado in varchar2) return number is 
vn_id_cidade  number;
e_cidade_null exception;
e_sg_null     exception;
begin
  --
  if p_sg_estado is null then
    raise e_sg_null;
  end if;
  --
  if p_nm_cidade is null then
    raise e_cidade_null;
  end if;
  --
  select c.id_cidade
    into vn_id_cidade
    from t_pr_estado e
       , t_pr_cidade c
    where c.id_estado = e.id_estado
      and c.nm_cidade = upper(p_nm_cidade)
      and e.sg_estado = upper(p_sg_estado);
  --
  return vn_id_cidade;
  --
exception
  when e_cidade_null then
    raise_application_error (-20000, 'A Cidade não foi informada.');
  when e_sg_null then
    raise_application_error (-20000, 'A sigla esta nula.');
  when no_data_found then
    raise_application_error (-20000, 'Nada encontrado.');
  when others then
    raise_application_error (-20000, 'obtem_id_cidade: ' || sqlerrm);
end obtem_id_cidade;
/
sho err
--
create or replace function existe_cidade(p_nm_cidade in varchar2
                                        ,p_sg_estado in varchar2) return boolean is 
vn_count       number;
e_cidade_null exception;
e_sg_null     exception;
begin
  --
  if p_sg_estado is null then
    raise e_sg_null;
  end if;
  --
  if p_nm_cidade is null then
    raise e_cidade_null;
  end if;
  --
  select count(1)
    into vn_count
    from t_pr_estado e
       , t_pr_cidade c
    where c.id_estado = e.id_estado
      and c.nm_cidade = upper(p_nm_cidade)
      and e.sg_estado = upper(p_sg_estado);
  --
  if vn_count > 0 then 
    return true;
  else
    return false;
  end if;
  --
exception
  when e_cidade_null then
    raise_application_error (-20000, 'A Cidade não foi informada.');
  when e_sg_null then
    raise_application_error (-20000, 'A sigla esta nula.');
  when others then
    raise_application_error (-20000, 'existe_cidade: ' || sqlerrm);
end existe_cidade;
/
sho err
--
create or replace procedure insere_bairro (p_sg_estado in varchar2
                                          ,p_nm_cidade in varchar2
                                          ,p_nm_bairro in varchar2) is
e_cidade_null exception;
e_sg_null     exception;
e_bairro_null exception;
vrt_bairro    t_pr_bairro%rowtype;
begin
  --
  if p_nm_cidade is null then
    raise e_cidade_null;
  end if;
  --
  if p_sg_estado is null then
    raise e_sg_null;
  end if;
  --
  if p_nm_bairro is null then
    raise e_bairro_null;
  end if;
  --
  --
  vrt_bairro.id_bairro := sq_pr_bairro.nextval;
  --
  if not existe_cidade(p_nm_cidade => p_nm_cidade
                      ,p_sg_estado => p_sg_estado) then
    --
    insere_cidade(p_sg_estado => p_sg_estado
                 ,p_nm_cidade => p_nm_cidade);
    --
  end if;
  --
  vrt_bairro.id_cidade := obtem_id_cidade(p_nm_cidade => p_nm_cidade
                                         ,p_sg_estado => p_sg_estado) ;
  --
  vrt_bairro.nm_bairro := upper(p_nm_bairro);
  --
  insert into t_pr_bairro values vrt_bairro;
  --
exception
  when e_bairro_null then
    raise_application_error(-20000, 'Informe o nome do bairro.');
  when e_sg_null then
    raise_application_error(-20000, 'A sigla deve ser informada.');
  when e_cidade_null then
    raise_application_error(-20000, 'O Nome da cidade esta nulo.');
  when others then
    raise_application_error(-20000, 'insere_bairro: '||sqlerrm);
end insere_bairro;
/
sho err
--
create or replace function obtem_id_bairro(p_nm_bairro in varchar2
                                          ,p_nm_cidade in varchar2
                                          ,p_sg_estado in varchar2) return number is 
vn_id_bairro number;
e_cidade_null exception;
e_sg_null     exception;
e_bairro_null exception;
begin
  --
  if p_nm_cidade is null then
    raise e_cidade_null;
  end if;
  --
  if p_sg_estado is null then
    raise e_sg_null;
  end if;
  --
  if p_nm_bairro is null then
    raise e_bairro_null;
  end if;
  --
  select b.id_bairro
    into vn_id_bairro
    from t_pr_estado e
       , t_pr_cidade c
       , t_pr_bairro b
    where c.id_estado = e.id_estado
      and b.id_cidade = c.id_cidade
      and c.nm_cidade = upper(p_nm_cidade)
      and e.sg_estado = upper(p_sg_estado)
      and b.nm_bairro = upper(p_nm_bairro);
  --
  return vn_id_bairro;
  --
exception
  when e_bairro_null then
    raise_application_error(-20000, 'Informe o nome do bairro.');
  when e_sg_null then
    raise_application_error(-20000, 'A sigla deve ser informada.');
  when e_cidade_null then
    raise_application_error(-20000, 'O Nome da cidade esta nulo.');
  when no_data_found then
    raise_application_error(-20000, 'Bairro não cadastrado.');
  when others then
    raise_application_error (-20000, 'obtem_id_bairro: ' || sqlerrm);
end obtem_id_bairro;
/
sho err
--
create or replace function existe_bairro(p_nm_bairro in varchar2
                                        ,p_nm_cidade in varchar2
                                        ,p_sg_estado in varchar2) return boolean is 
vn_count number;
e_cidade_null exception;
e_sg_null     exception;
e_bairro_null exception;
begin
  --
  if p_nm_cidade is null then
    raise e_cidade_null;
  end if;
  --
  if p_sg_estado is null then
    raise e_sg_null;
  end if;
  --
  if p_nm_bairro is null then
    raise e_bairro_null;
  end if;
  --
  select count(1)
    into vn_count
    from t_pr_estado e
       , t_pr_cidade c
       , t_pr_bairro b
    where c.id_estado = e.id_estado
      and b.id_cidade = c.id_cidade
      and c.nm_cidade = upper(p_nm_cidade)
      and e.sg_estado = upper(p_sg_estado)
      and b.nm_bairro = upper(p_nm_bairro);
  --
  if vn_count > 0 then
    return true;
  else
    return false;
  end if;
  --
exception
  when e_bairro_null then
    raise_application_error(-20000, 'Informe o nome do bairro.');
  when e_sg_null then
    raise_application_error(-20000, 'A sigla deve ser informada.');
  when e_cidade_null then
    raise_application_error(-20000, 'O Nome da cidade esta nulo.');
  when others then
    raise_application_error (-20000, 'existe_bairro: ' || sqlerrm);
end existe_bairro;
/
sho err
--
create or replace function insere_endereco(p_nm_bairro     in varchar2
                                          ,p_nm_cidade     in varchar2
                                          ,p_sg_estado     in varchar2
                                          ,p_nr_cep        in varchar2
                                          ,p_ds_logradouro in varchar2) return number is
vrt_endereco t_pr_endereco%rowtype;
vv_cep       varchar2(12);
e_tam_cep    exception;
e_logra_null exception;
begin
  --
  if not existe_bairro(p_nm_bairro => p_nm_bairro
                      ,p_nm_cidade => p_nm_cidade
                      ,p_sg_estado => p_sg_estado) then
    --
    insere_bairro (p_sg_estado => p_sg_estado
                  ,p_nm_cidade => p_nm_cidade
                  ,p_nm_bairro => p_nm_bairro);
    --
  end if;
  --
  vrt_endereco.id_bairro := obtem_id_bairro(p_nm_bairro => p_nm_bairro
                                           ,p_nm_cidade => p_nm_cidade
                                           ,p_sg_estado => p_sg_estado);
  --
  vv_cep := REGEXP_REPLACE(p_nr_cep, '-');
  --
  if LENGTH(vv_cep) > 8 then
    raise e_tam_cep;
  end if;
  --
  if p_ds_logradouro is null then
    raise e_logra_null;
  end if;
  vrt_endereco.nr_cep := to_number(vv_cep);
  --
  vrt_endereco.ds_logradouro := upper(p_ds_logradouro);
  --
  vrt_endereco.id_endereco   := sq_pr_endereco.nextval ;
  --
  insert into t_pr_endereco values vrt_endereco;
  --
  return vrt_endereco.id_endereco  ;
  --
exception
  when e_logra_null then
    raise_application_error (-20000, 'Informe o Logradouro.');
  when e_tam_cep then
    raise_application_error (-20000, 'O limite do tamanho do Cep é 8 .');
  when others then
    raise_application_error (-20000, 'insere_endereco: ' || sqlerrm);
end insere_endereco;
/
sho err
--
create or replace procedure insere_restaurante_completa(p_nome_restaurante in varchar2
                                                       ,p_nm_cnpj_rest     in varchar2
                                                       ,p_nr_cnpj_rest     in varchar2
                                                       ,p_email            in varchar2
                                                       ,p_nr_telefone      in number
                                                       ,p_nr_ddd           in number
                                                       ,p_nr_ddi           in number
                                                       ,p_ds_telefone      in varchar2
                                                       ,p_nm_bairro        in varchar2
                                                       ,p_nm_cidade        in varchar2
                                                       ,p_sg_estado        in varchar2
                                                       ,p_nr_cep           in varchar2
                                                       ,p_ds_logradouro    in varchar2 ) is 
vn_id_endereco    number;
vn_id_restaurante number;
e_cnpj_duplicado  exception;
e_endereco_null   exception;
begin
  --
  -- ve se existe
  if cnpj_existe(p_nr_cnpj_rest => p_nr_cnpj_rest) then
    raise e_cnpj_duplicado;
  else
    insere_restaurante_telefone(p_nome_restaurante => p_nome_restaurante
                               ,p_nm_cnpj_rest     => p_nm_cnpj_rest
                               ,p_nr_cnpj_rest     => p_nr_cnpj_rest
                               ,p_email            => p_email
                               ,p_nr_telefone      => p_nr_telefone
                               ,p_nr_ddd           => p_nr_ddd
                               ,p_nr_ddi           => p_nr_ddi
                               ,p_ds_telefone      => p_ds_telefone );
  end if;
  --
  vn_id_endereco := insere_endereco(p_nm_bairro     => p_nm_bairro
                                   ,p_nm_cidade     => p_nm_cidade
                                   ,p_sg_estado     => p_sg_estado
                                   ,p_nr_cep        => p_nr_cep
                                   ,p_ds_logradouro => p_ds_logradouro);
  --
  if vn_id_endereco is null then
    raise e_endereco_null ;
  end if;
  --
  vn_id_restaurante := obtem_id_restaurante(p_nr_cnpj => p_nr_cnpj_rest);
  --
  insert into T_PR_END_REST(ID_ENDERECO,ID_RESTAURANTE )
               values(vn_id_endereco,vn_id_restaurante);
  --
  commit;
  --
exception
  when e_endereco_null then
    raise_application_error(-20000, 'Não foi possível inserir o endereço '||sqlerrm);
  when e_cnpj_duplicado then
    raise_application_error(-20000, 'CNPJ já cadastrado.');
  when others then
    raise_application_error(-20000, 'insere_restaurante_completa: '||sqlerrm);
end insere_restaurante_completa;
/
sho err