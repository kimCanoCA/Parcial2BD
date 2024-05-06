CREATE TABLE products(
products_id NUMBER PRIMARY KEY,
product_name VARCHAR2(100)
);
//0
CREATE TABLE mines(
mines_id NUMBER PRIMARY KEY,
mine_name VARCHAR2(100),
products_id NUMBER,
FOREIGN KEY (products_id) REFERENCES products (products_id)
);
//1
CREATE TABLE persons(
persons_id NUMBER PRIMARY KEY,
NAME VARCHAR2(50),
lastname VARCHAR2(50),
sex CHAR,
birthdate DATE
);
//2
CREATE TABLE DIAGNOSTICS(
diagnostics_id NUMBER PRIMARY KEY,
diagnosty VARCHAR2(100),
DESCRIPTION VARCHAR2(200)
);
//3
CREATE TABLE deaths(
deaths_id NUMBER PRIMARY KEY,
type_death VARCHAR2(100)
);
//4
CREATE TABLE workers(
workers_id NUMBER PRIMARY KEY,
mines_id NUMBER,
persons_id NUMBER,
ingressdate DATE,
FOREIGN KEY (mines_id) REFERENCES mines (mines_id),
FOREIGN KEY (persons_id) REFERENCES persons (persons_id)
);
//5
CREATE TABLE persons_medical_check(
persons_medical_check_id NUMBER PRIMARY KEY,
persons_id NUMBER,
diagnostics_id NUMBER,
FOREIGN KEY (persons_id) REFERENCES persons (persons_id),
FOREIGN KEY (diagnostics_id) REFERENCES DIAGNOSTICS (diagnostics_id)
);
//6
CREATE TABLE persons_defuntions(
persons_defuntions_id NUMBER PRIMARY KEY,
fecha DATE,
persons_id NUMBER,
deaths_id NUMBER,
FOREIGN KEY (persons_id) REFERENCES persons(persons_id),    
FOREIGN KEY (deaths_id) REFERENCES deaths(deaths_id)
);
//7
CREATE TABLE product_worker(
product_worker_id NUMBER PRIMARY KEY,
products_id NUMBER,
persons_id NUMBER,
kg_product NUMBER,
FOREIGN KEY (products_id) REFERENCES products(products_id),    
FOREIGN KEY (persons_id) REFERENCES persons(persons_id)    
);

commit;

--1 - Generar una función que retorne cuantos años tiene una persona.

CREATE OR REPLACE FUNCTION person_age(person_birthdate DATE) 
RETURN NUMBER
 IS
    var_age NUMBER;
BEGIN
    SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, person_birthdate) / 12) INTO var_age FROM dual;
    RETURN var_age;
END;
SELECT person_age(birthdate) AS edad FROM persons WHERE persons_id =91;

--2 - los niños y viejos y enfermos no pueden trabajar en la mina. por ello cree un trigger que sea capaz de garantizar que ningún empleado viole esas
--restricciones. Nota: niño es considerado inferior a 12 años y un viejo es alguien mayor de 70 años Recuerda que no se admiten personas enfermas.

CREATE OR REPLACE TRIGGER conditions_to_work
BEFORE INSERT OR UPDATE ON persons FOR EACH ROW
 DECLARE
   var_age NUMBER;
   var_sick NUMBER;
   
BEGIN
  var_age:= EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM :NEW.birthdate);
    
 IF var_age< 12 OR var_age > 70 THEN
 RAISE_APPLICATION_ERROR(-20001, 'El empleado no comple la edad establesida para trabajar');
   END IF;
   
  SELECT diagnostics_id INTO var_sick FROM persons_medical_check  WHERE persons_id = :NEW.persons_id;
    IF var_sick != 1 THEN
    RAISE_APPLICATION_ERROR(-20002, 'El empleado está enfermo y no puede trabajar en la mina.');
      END IF;
END;

INSERT INTO persons VALUES (1001,'Juan','Lopez','M',TO_DATE('2024-1-1', 'yyyy/mm/dd'));

--3 - Cree un procedimiento que registre un trabajador. tabla: workers Nota: validar que la persona exista antes de registrar como trabajador.

CREATE OR REPLACE PROCEDURE 
register_worker(var_worker_id workers.workers_id%type,var_mines_id workers.mines_id%type,var_person_id workers.persons_id%type)
AS
  var_check_id number;
  
BEGIN
 SELECT COUNT(*) INTO var_check_id FROM persons WHERE persons_id = var_person_id;
  
IF var_check_id= 0 THEN
   RAISE_APPLICATION_ERROR(-20001,'La persona no se encuentra registrada.');
ELSE
    INSERT INTO workers VALUES (var_worker_id, var_mines_id, var_person_id,SYSDATE);
    DBMS_OUTPUT.PUT_LINE('Trabajador registrado correctamente');    
     END IF;
END;

--4 - crear un cursor que muestre el id, nombre, apellido, fecha de nacimiento de todas las mujeres que trabajan en una mina, 
--la mina debe ser indicada por entrada de teclado.


CREATE OR REPLACE PROCEDURE women_of_a_mine(mine mines.mine_name%type )
AS
 BEGIN
  
  FOR i IN(SELECT p.persons_id as person_, p.name as nameP_, p.lastname as lastN_, p.birthdate as birthD_ FROM persons p 
   INNER JOIN workers w ON p.persons_id = w.persons_id  
   INNER JOIN mines m ON w.mines_id = m.mines_id 
   WHERE LOWER(m.mine_name) = LOWER(mine) AND p.sex = 'F') LOOP
    DBMS_OUTPUT.PUT_LINE('mujer_id: '||i.person_||' |Nombre: '||i.nameP_||' |Apellidos: '||i.lastN_||' |F_Nacimiento: '||i.birthD_);
END LOOP;
END;

--5 - crear una función que retorne si un trabajador está vivo o muerto.
CREATE OR REPLACE FUNCTION alive_dead(worker workers.workers_id%TYPE)
RETURN VARCHAR2
  IS
    var_person_state NUMBER;
    var_boolean boolean;
 BEGIN
   BEGIN
       var_boolean:=true;
  SELECT persons_id into var_person_state FROM persons_defuntions WHERE persons_id=worker;
    RETURN 'EL trabajador idendificado con el ID: '||worker||' ha perdido la vida';
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN var_boolean:=false;
      RETURN 'El trabajador idendificado con el ID: '||worker||' esta con vida';
  END;
END;
SELECT alive_dead(799) FROM dual;

--6 - crear una función que retorne la cantidad de kilos que produce de una mina.

CREATE OR REPLACE FUNCTION count_kilos_mine(mine mines.mine_name%TYPE)
RETURN VARCHAR
 IS
    var_count_kg varchar(400);
    mine_kgs NUMBER;
BEGIN

    SELECT SUM(pw.KG_PRODUCT)as mine_kgs into mine_kgs FROM PRODUCT_WORKER pw inner join mines m on pw.PRODUCTS_ID= m.PRODUCTS_ID 
    AND LOWER(m.mine_name)=LOWER(mine) GROUP BY m.mine_name;
    
      RETURN 'Nombre mina: '||mine||' |la cantidad total de kilos de la mina son: '||mine_kgs||'Kilos';
END;
SELECT count_kilos_mine('&Seleccionar_mina') FROM dual;

--7 - Generar un CURSOR de trabajadores que muestre: id, nombre, apellido, sexo, edad de todos los menores de edad que han muerto.

DECLARE
  CURSOR dead_workers_data
IS

  SELECT p.persons_id AS id_person, p.name AS nameP, p.lastname AS lastN, p.sex AS sexP,(sysdate - p.birthdate)/365 AS ageP FROM persons p
  INNER JOIN persons_defuntions pf ON pf.persons_id = p.persons_id WHERE (sysdate - p.birthdate) <= 6570 ;
BEGIN

FOR i IN dead_workers_data LOOP
DBMS_OUTPUT.PUT_LINE('ID: ' || i.id_person ||'  Nombre: ' || i.nameP || ' Apellido: ' || i.lastN ||'  Sexo: ' || i.sexP || ' Edad: ' || i.ageP );
  END LOOP;
END;

--8 - Generar un procedimiento que dando el nombre una mina que se ingresa por teclado retorne la cantidad de trabajadores infectados con VIH.

CREATE OR REPLACE PROCEDURE number_infected_VIH(mine mines.mine_name%TYPE)
AS
 number_of_infected NUMBER;

BEGIN

SELECT COUNT(*) INTO number_of_infected FROM persons p 
   INNER JOIN persons_medical_check pmc ON p.persons_id = pmc.persons_id
   INNER JOIN workers w ON p.persons_id = w.persons_id 
   INNER JOIN mines m ON w.mines_id = m.mines_id  WHERE LOWER(m.mine_name) = LOWER(mine) AND pmc.diagnostics_id = 2;
   DBMS_OUTPUT.PUT_LINE('La cantidad de infectados en la mina: '||mine|| ' son de : ' ||number_of_infected||' infectados  ');
END;

--9 - Cree un procedimiento que muestre el mejor trabajador de cada mina.
SET SERVEROUTPUT ON;
CREATE OR REPLACE PROCEDURE best_worker
AS
var_person VARCHAR(300);

BEGIN

FOR i IN (SELECT m1.mine_name AS mine, q1.persons_id AS person, MAX(q1.suma) AS total_kilos FROM (
   SELECT M.mine_name, pw.persons_id, SUM(pw.kg_product) AS suma FROM product_worker pw
    INNER JOIN mines M ON pw.products_id = M.products_id GROUP BY M.mine_name, pw.persons_id)  
q1
 INNER JOIN (SELECT mine_name, MAX(suma) AS max_sum
    FROM (SELECT M.mine_name, pw.persons_id, SUM(pw.kg_product) AS suma FROM product_worker pw
     INNER JOIN mines M ON pw.products_id = M.products_id GROUP BY M.mine_name, pw.persons_id)  GROUP BY mine_name) 
     m1 ON q1.mine_name = m1.mine_name AND q1.suma = m1.max_sum GROUP BY m1.mine_name, q1.persons_id) LOOP

 SELECT NAME INTO var_person FROM persons WHERE persons_id= i.person;
    DBMS_OUTPUT.PUT_LINE('El trabajador: '||var_person||' |ID: '||I.person||' |fue el mejor trabajador de la mina: '||UPPER(I.mine)||' |obtuvo: '||I.total_kilos||'Kilos recolectados');
   
   END LOOP;
END;