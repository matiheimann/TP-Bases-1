
SET DATESTYLE TO DMY;

CREATE OR REPLACE FUNCTION selectSecond(param1 INTEGER,param2 TIMESTAMP) RETURNS INTEGER
AS $$
DECLARE
	pointer auxWithoutNULL;
	basura auxWithoutNULL;
	pointerCursor CURSOR FOR
	SELECT * FROM auxWithoutNULL
	WHERE usuario = param1 and fecha_hora_ret = param2
	ORDER BY tiempo_uso ASC;

BEGIN

	OPEN pointerCursor;

	FETCH pointerCursor INTO basura;
	FETCH pointerCursor INTO pointer;

	CLOSE pointerCursor;

	INSERT INTO auxWithoutRepeated VALUES(pointer.periodo, pointer.usuario, pointer.fecha_hora_ret, pointer.est_origen, pointer.est_destino, pointer.tiempo_uso);

	RETURN 1;
END;
$$ LANGUAGE plpgSQL;

--Para eliminar los repetidos usuario+fecha_hora_ret
CREATE OR REPLACE FUNCTION removeRepeated() RETURNS INTEGER
AS $$
DECLARE
		value1 auxWithoutNULL.usuario%TYPE;
		value2 auxWithoutNULL.fecha_hora_ret%TYPE;
 		myCursor CURSOR FOR
		SELECT DISTINCT usuario, fecha_hora_ret FROM auxWithoutNULL
		GROUP BY usuario, fecha_hora_ret
		HAVING count(usuario) > 1;

BEGIN
		OPEN myCursor;
		LOOP

			FETCH myCursor INTO value1, value2;
			EXIT WHEN NOT FOUND;
			PERFORM selectSecond(value1, value2);

		END LOOP;
		CLOSE myCursor;

		RETURN 1;
END;
$$ LANGUAGE plpgSQL;

CREATE OR REPLACE FUNCTION migracion() RETURNS INTEGER
AS $$
BEGIN
--\copy aux FROM '/home/jkatan/Escritorio/test1.csv'  DELIMITER ';' CSV HEADER;
SET datestyle TO postgres, dmy;

	--Se borran los tiempo_uso invalidos
	DELETE FROM aux WHERE tiempo_uso LIKE '%-%';
	UPDATE aux SET tiempo_uso = REPLACE(REPLACE(tiempo_uso, 'MIN', 'm'), 'SEG', 's');

	--Se crea una tabla auxiliar donde no estan los valores en NULL, y los tiempo_uso son validos
	INSERT INTO auxWithoutNULL
	SELECT
	periodo, CAST(usuario AS INTEGER), CAST(fecha_hora_ret AS TIMESTAMP), CAST(est_origen AS INTEGER), CAST(est_destino AS INTEGER), CAST(tiempo_uso AS INTERVAL)
	FROM aux
	WHERE usuario IS NOT NULL AND fecha_hora_ret IS NOT NULL AND est_origen IS NOT NULL AND
		est_destino IS NOT NULL AND tiempo_uso IS NOT NULL;

	CREATE TABLE auxWithoutRepeated AS(
	SELECT * FROM auxWithoutNULL
	WHERE (usuario, fecha_hora_ret) IN (
		SELECT a2.usuario, a2.fecha_hora_ret FROM auxWithoutNULL a2
		GROUP BY a2.usuario, a2.fecha_hora_ret
		HAVING count(a2.usuario) = 1
	));

 PERFORM removeRepeated();

 INSERT INTO auxWithFechaDev SELECT periodo, usuario, fecha_hora_ret, est_origen, est_destino, (fecha_hora_ret + tiempo_uso)
 FROM auxWithoutRepeated;

 PERFORM removeOverlapped();

	RETURN 1;
END;
$$ LANGUAGE plpgSQL;

--Remover intervalos solapados
CREATE OR REPLACE FUNCTION removeOverlapped() RETURNS INTEGER
AS $$
DECLARE
		value auxWithFechaDev.usuario%TYPE;
 		myCursor CURSOR FOR
		SELECT DISTINCT usuario FROM auxWithFechaDev;

BEGIN
		OPEN myCursor;
		LOOP

			FETCH myCursor INTO value;
			EXIT WHEN NOT FOUND;
			PERFORM fixOverlaps(value);

		END LOOP;
		CLOSE myCursor;

		RETURN 1;
END;
$$ LANGUAGE plpgSQL;

CREATE OR REPLACE FUNCTION fixOverlaps(param auxWithFechaDev.usuario%TYPE) RETURNS INTEGER
AS $$
DECLARE
	value1 auxWithFechaDev;
	fechaInicial auxWithFechaDev.fecha_hora_ret%TYPE;
	fechaFinal auxWithFechaDev.fecha_hora_dev%TYPE;
	minEstacion auxWithFechaDev.est_origen%TYPE;
	maxEstacion auxWithFechaDev.est_destino%TYPE;
	periodo auxWithFechaDev.periodo%TYPE;

	myCursor2 CURSOR FOR
	SELECT * FROM auxWithFechaDev
	WHERE usuario = param
	ORDER BY fecha_hora_ret ASC;

BEGIN

		OPEN myCursor2;
		FETCH myCursor2 INTO value1;

		LOOP

			EXIT WHEN value1 ISNULL;

			fechaInicial = value1.fecha_hora_ret;
			fechaFinal = value1.fecha_hora_dev;
			minEstacion = value1.est_origen;
			maxEstacion = value1.est_destino;
			periodo = value1.periodo;

			LOOP

			FETCH myCursor2 INTO value1;
			EXIT WHEN NOT FOUND OR value1.fecha_hora_ret > fechaFinal;

			IF fechaFinal < value1.fecha_hora_dev THEN
				fechaFinal = value1.fecha_hora_dev;
				maxEstacion = value1.est_destino;
			END IF;

			END LOOP;

			INSERT INTO recorrido_final VALUES(periodo, param, fechaInicial, minEstacion, maxEstacion, fechaFinal);

		END LOOP;

		CLOSE myCursor2;
RETURN 1;
END;
$$ LANGUAGE plpgSQL;

CREATE TRIGGER detecta_solapado
BEFORE INSERT ON recorrido_final
FOR EACH ROW
EXECUTE PROCEDURE validateOverlap();

CREATE OR REPLACE FUNCTION validateOverlap() RETURNS trigger
AS $$
DECLARE
        cantOverlaps int;
BEGIN
				cantOverlaps = (SELECT COUNT(*) FROM recorrido_final
				WHERE NEW.usuario = usuario AND ((NEW.fecha_hora_dev >= fecha_hora_ret AND NEW.fecha_hora_ret <= fecha_hora_ret)
				OR (NEW.fecha_hora_dev >= fecha_hora_dev AND NEW.fecha_hora_ret <= fecha_hora_dev)
				OR (NEW.fecha_hora_dev <= fecha_hora_dev AND NEW.fecha_hora_dev >= fecha_hora_ret)
				OR (NEW.fecha_hora_ret <= fecha_hora_dev AND NEW.fecha_hora_ret >= fecha_hora_ret)));

				IF cantOverlaps > 0 THEN
				RAISE EXCEPTION 'Error, se esta ingresando un intervalo solapado';
				END IF;

				RETURN NEW;
END;
$$ LANGUAGE plpgsql;
