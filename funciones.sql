
SET DATESTYLE TO DMY;

CREATE OR REPLACE FUNCTION selectSecond(param1 INTEGER,param2 TIMESTAMP) RETURNS INTEGER
AS $$
DECLARE
	pointer auxWithoutNULL;
	firstFetch auxWithoutNULL;
	pointerCursor CURSOR FOR
	SELECT * FROM auxWithoutNULL
	WHERE usuario = param1 and fecha_hora_ret = param2
	ORDER BY tiempo_uso ASC;

BEGIN

	OPEN pointerCursor;

	FETCH pointerCursor INTO firstFetch;
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

CREATE OR REPLACE FUNCTION fixOverlaps(param INTEGER) RETURNS INTEGER
AS $$
DECLARE
	value1 auxWithFechaDev;
	fechaInicial TIMESTAMP;
	fechaFinal TIMESTAMP;
	minEstacion INTEGER;
	maxEstacion INTEGER;
	periodo TEXT;

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

			fechaFinal = value1.fecha_hora_dev;
			maxEstacion = value1.est_destino;

			END LOOP;

			INSERT INTO recorrido_final VALUES(periodo, param, fechaInicial, minEstacion, maxEstacion, fechaFinal);

		END LOOP;

		CLOSE myCursor2;
RETURN 1;
END;
$$ LANGUAGE plpgSQL;

--Remover intervalos solapados
CREATE OR REPLACE FUNCTION removeOverlapped() RETURNS INTEGER
AS $$
DECLARE
		value INTEGER;
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


CREATE OR REPLACE FUNCTION dropAuxTables() RETURNS VOID
AS $$
BEGIN
	DROP TABLE aux;
	DROP TABLE auxWithoutNULL;
	DROP TABLE auxWithFechaDev;
	DROP TABLE auxWithoutRepeated;
END;
$$ LANGUAGE plpgSQL;
