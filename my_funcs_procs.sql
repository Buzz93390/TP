CREATE OR REPLACE FUNCTION GET_NB_WORKERS(FACTORY VARCHAR2) 
RETURN NUMBER 
IS
  nb_workers NUMBER;
BEGIN
  SELECT COUNT(*) INTO nb_workers
  FROM ALL_WORKERS
  WHERE EXISTS (
    SELECT 1
    FROM ROBOTS_FACTORIES rf
    WHERE rf.main_location = FACTORY
      AND (rf.factory_id = ALL_WORKERS.factory_id)
  );

  RETURN nb_workers;
END;


CREATE OR REPLACE FUNCTION GET_NB_BIG_ROBOTS 
RETURN NUMBER 
IS
  nb_big_robots NUMBER;
BEGIN
  SELECT COUNT(*) INTO nb_big_robots
  FROM (
    SELECT rf.robot_id
    FROM ROBOTS_HAS_SPARE_PARTS rhsp
    JOIN ROBOTS_FACTORIES rf ON rhsp.robot_id = rf.robot_id
    GROUP BY rf.robot_id
    HAVING COUNT(rhsp.spare_part_id) > 3
  );

  RETURN nb_big_robots;
END;

CREATE OR REPLACE FUNCTION GET_BEST_SUPPLIER 
RETURN VARCHAR2 
IS
  best_supplier VARCHAR2(100);
BEGIN
  SELECT name INTO best_supplier
  FROM BEST_SUPPLIERS
  WHERE ROWNUM = 1
  ORDER BY total_delivered DESC;

  RETURN best_supplier;
END;

CREATE OR REPLACE FUNCTION GET_NB_WORKERS(FACTORY NUMBER) 
RETURN NUMBER 
IS
  nb_workers NUMBER;
BEGIN
  SELECT COUNT(*) INTO nb_workers
  FROM (
    SELECT first_day AS start_date FROM WORKERS_FACTORY_1 WHERE last_day IS NULL
    UNION ALL
    SELECT start_date FROM WORKERS_FACTORY_2 WHERE end_date IS NULL
  )
  WHERE EXISTS (
    SELECT 1
    FROM ROBOTS_FACTORIES rf
    WHERE rf.factory_id = FACTORY
      AND (
        (rf.factory_id = FACTORY AND rf.main_location IS NOT NULL)
      )
  );

  RETURN nb_workers;
END;


CREATE OR REPLACE PROCEDURE SEED_DATA_WORKERS(NB_WORKERS NUMBER, FACTORY_ID NUMBER) 
IS
  random_date DATE;
BEGIN
  FOR i IN 1..NB_WORKERS LOOP
    -- Générer une date aléatoire entre le 01/01/2065 et le 01/01/2070
    SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2065-01-01','J'), TO_CHAR(DATE '2070-01-01','J'))), 'J') 
    INTO random_date 
    FROM DUAL;

    INSERT INTO WORKERS_FACTORY_1 (id, first_name, last_name, age, first_day, last_day, factory_id)
    VALUES (
      WORKERS_FACTORY_1_SEQ.NEXTVAL, 
      'worker_f_' || WORKERS_FACTORY_1_SEQ.CURRVAL, 
      'worker_l_' || WORKERS_FACTORY_1_SEQ.CURRVAL, 
      TRUNC(DBMS_RANDOM.VALUE(20, 60)), 
      random_date,
      NULL,
      FACTORY_ID
    );
  END LOOP;
END;

CREATE OR REPLACE PROCEDURE ADD_NEW_ROBOT (model_name VARCHAR2(50)) IS
BEGIN
