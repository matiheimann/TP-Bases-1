DROP TABLE recorrido_final;

CREATE TABLE recorrido_final
(periodo TEXT,
usuario INTEGER,
fecha_hora_ret TIMESTAMP NOT NULL,
est_origen INTEGER NOT NULL,
est_destino INTEGER NOT NULL,
fecha_hora_dev TIMESTAMP NOT NULL CHECK(fecha_hora_dev >= fecha_hora_ret)
);

TRUNCATE TABLE recorrido_final;

CREATE OR REPLACE FUNCTION migracion() RETURNS INTEGER
AS $$
BEGIN
	
	CREATE TABLE aux
	(periodo TEXT,
	usuario INTEGER,
	fecha_hora_ret TIMESTAMP ,
	est_origen INTEGER,
	nombre_origen TEXT,
	est_destino INTEGER ,
	nombre_destino TEXT,
	tiempo_uso 	TEXT,
	fecha_creacion TEXT
	);

	COPY aux FROM '/home/lorant/Desktop/tp-bases/TP-Bases-1/test1.csv'  DELIMITER ';' CSV HEADER;


	INSERT INTO recorrido_final
	SELECT 
	periodo, usuario, fecha_hora_ret, est_origen, est_destino, fecha_hora_ret 
	FROM AUX 
	WHERE usuario IS NOT NULL AND fecha_hora_ret IS NOT NULL AND est_origen IS NOT NULL AND
		est_destino IS NOT NULL AND tiempo_uso IS NOT NULL ;

	RETURN 1;
END
$$ LANGUAGE plpgSQL;
SELECT migracion();

SELECT * FROM recorrido_final;
