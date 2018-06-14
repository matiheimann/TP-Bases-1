
SET DATESTYLE TO DMY;

CREATE OR REPLACE FUNCTION migracion() RETURNS INTEGER
AS $$
BEGIN
--\copy aux FROM '/home/jkatan/Escritorio/test1.csv'  DELIMITER ';' CSV HEADER;
SET datestyle TO postgres, dmy;

	--Se borran los tiempo_uso invalidos
	DELETE FROM aux WHERE tiempo_uso LIKE '%-%';
	UPDATE aux SET tiempo_uso = CAST(REPLACE(REPLACE(tiempo_uso, 'MIN', 'm'), 'SEG', 's') AS INTERVAL) + CAST(fecha_hora_ret AS TIMESTAMP);

	--Se crea una tabla auxiliar donde no estan los valores en NULL, y los tiempo_uso son validos
	INSERT INTO auxWithoutNULL
	SELECT
	periodo, CAST(usuario AS INTEGER), CAST(fecha_hora_ret AS TIMESTAMP), CAST(est_origen AS INTEGER), tiempo_uso
	FROM aux
	WHERE usuario IS NOT NULL AND fecha_hora_ret IS NOT NULL AND est_origen IS NOT NULL AND
		est_destino IS NOT NULL AND tiempo_uso IS NOT NULL;

	RETURN 1;
END;
$$ LANGUAGE plpgSQL;
SELECT migracion();

SELECT * FROM recorrido_final;
