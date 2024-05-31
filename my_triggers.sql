CREATE OR REPLACE TRIGGER trg_insert_all_workers_elapsed
INSTEAD OF INSERT ON ALL_WORKERS_ELAPSED
FOR EACH ROW
BEGIN
  INSERT INTO WORKERS (worker_id, firstname, lastname, age, start_date)
  VALUES (:NEW.worker_id, :NEW.firstname, :NEW.lastname, :NEW.age, :NEW.start_date);
END;
/

CREATE OR REPLACE TRIGGER trg_no_update_delete_all_workers_elapsed
BEFORE UPDATE OR DELETE ON ALL_WORKERS_ELAPSED
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20001, 'Updates and deletions are not allowed on ALL_WORKERS_ELAPSED');
END;
/

CREATE OR REPLACE TRIGGER trg_audit_robot
AFTER INSERT ON ROBOTS
FOR EACH ROW
BEGIN
  INSERT INTO AUDIT_ROBOT (robot_id, date_added)
  VALUES (:NEW.robot_id, SYSDATE);
END;
/

CREATE OR REPLACE TRIGGER trg_check_factories
BEFORE INSERT OR UPDATE OR DELETE ON FACTORIES
FOR EACH ROW
DECLARE
  v_factory_count NUMBER;
  v_worker_table_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_factory_count FROM FACTORIES;
  SELECT COUNT(*) INTO v_worker_table_count FROM USER_TABLES WHERE TABLE_NAME LIKE 'WORKERS_FACTORY_%';

  IF v_factory_count != v_worker_table_count THEN
    RAISE_APPLICATION_ERROR(-20002, 'Number of factories does not match the number of WORKERS_FACTORY_<N> tables');
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_worker_departure
BEFORE UPDATE OF departure_date ON WORKERS
FOR EACH ROW
BEGIN
  IF :NEW.departure_date IS NOT NULL THEN
    :NEW.duration := :NEW.departure_date - :OLD.start_date;
  END IF;
END;
/
