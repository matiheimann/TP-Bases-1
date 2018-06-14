
CREATE TABLE aux
	(periodo TEXT,
	usuario TEXT,
	fecha_hora_ret TEXT ,
	est_origen TEXT,
	nombre_origen TEXT,
	est_destino TEXT ,
	nombre_destino TEXT,
	tiempo_uso 	TEXT,
	fecha_creacion TEXT
	);

	CREATE TABLE auxWithoutNULL
	(periodo TEXT,
	usuario INTEGER,
	fecha_hora_ret TIMESTAMP NOT NULL,
	est_origen INTEGER NOT NULL,
	est_destino INTEGER NOT NULL,
	tiempo_uso INTERVAL NOT NULL
	--fecha_hora_dev TIMESTAMP NOT NULL CHECK(fecha_hora_dev >= fecha_hora_ret)
	);

CREATE TABLE recorrido_final
(periodo TEXT,
usuario INTEGER,
fecha_hora_ret TIMESTAMP NOT NULL,
est_origen INTEGER NOT NULL,
est_destino INTEGER NOT NULL,
fecha_hora_dev TIMESTAMP NOT NULL CHECK(fecha_hora_dev >= fecha_hora_ret)
);
