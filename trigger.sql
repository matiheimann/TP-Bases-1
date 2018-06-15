CREATE TRIGGER detecta_solapado
BEFORE INSERT ON recorrido_final
FOR EACH ROW
EXECUTE PROCEDURE validateOverlap();

CREATE OR REPLACE FUNCTION validateOverlap() RETURNS trigger
AS $$
DECLARE
        cantOverlaps INTEGER;
BEGIN
				cantOverlaps = (SELECT COUNT(*) FROM recorrido_final
				WHERE NEW.usuario = usuario AND (((NEW.fecha_hora_dev = fecha_hora_ret)  OR (fecha_hora_dev = NEW.fecha_hora_ret)) OR
				((NEW.fecha_hora_dev > fecha_hora_ret AND NEW.fecha_hora_ret < fecha_hora_ret) OR (fecha_hora_dev > NEW.fecha_hora_ret AND fecha_hora_ret < NEW.fecha_hora_ret)) OR
				(NEW.fecha_hora_ret = fecha_hora_ret) OR
				((NEW.fecha_hora_ret > fecha_hora_ret AND NEW.fecha_hora_dev < fecha_hora_dev) OR (fecha_hora_ret>NEW.fecha_hora_ret AND fecha_hora_dev < NEW.fecha_hora_dev)) OR
				(fecha_hora_dev = NEW.fecha_hora_dev) OR
				((NEW.fecha_hora_ret = fecha_hora_ret) AND (NEW.fecha_hora_dev = fecha_hora_dev))));

				IF cantOverlaps > 0 THEN
				RAISE EXCEPTION 'Error, se esta ingresando un intervalo solapado';
				END IF;

				RETURN NEW;
END;
$$ LANGUAGE plpgsql;
