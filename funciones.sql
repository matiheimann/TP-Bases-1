
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

		raise notice '%', value1;
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

	RETURN 1;
END;
$$ LANGUAGE plpgSQL;
