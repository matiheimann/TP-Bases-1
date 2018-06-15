CREATE OR REPLACE FUNCTION migracion() RETURNS VOID
AS $$
BEGIN
SET datestyle TO postgres, dmy;
DROP TABLE IF EXISTS recorrido_final;

CREATE TABLE recorrido_final
(periodo TEXT,
usuario INTEGER,
fecha_hora_ret TIMESTAMP NOT NULL,
est_origen INTEGER NOT NULL,
est_destino INTEGER NOT NULL,
fecha_hora_dev TIMESTAMP NOT NULL CHECK(fecha_hora_dev >= fecha_hora_ret),
PRIMARY KEY(usuario,fecha_hora_ret)
);

	--Se borran los tiempo_uso invalidos
	DELETE FROM aux WHERE tiempo_uso LIKE '%-%';
	UPDATE aux SET tiempo_uso = REPLACE(REPLACE(REPLACE(tiempo_uso, 'MIN', 'm'), 'SEG', 's'), ' ', '');

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
	ALTER TABLE auxWithoutRepeated ADD PRIMARY KEY (usuario,fecha_hora_ret);

 PERFORM removeRepeated();

 INSERT INTO auxWithFechaDev SELECT periodo, usuario, fecha_hora_ret, est_origen, est_destino, (fecha_hora_ret + tiempo_uso)
 FROM auxWithoutRepeated;

 PERFORM removeOverlapped();
 PERFORM dropAuxTables();
END;
$$ LANGUAGE plpgSQL;
