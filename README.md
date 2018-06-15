TP-Bases-1

Instrucciones para la correcta migración de los datos de recorridos-realizados-2016.csv:

1) En primer lugar, se debe ejecutar create_aux.sql, donde se creará una tabla
que se usa para importar el archivo .csv, y otras tablas auxiliares para el filtrado de información no deseada durante el proceso de migración.

2) Ahora, para importar el archivo .csv a una tabla auxiliar creada en el paso anterior, se deberá ejecutar desde la terminal el siguiente comando: "\copy aux FROM $PATH  DELIMITER ';' CSV HEADER;" donde en $PATH se deberá escribir la ubicación del archivo .csv. Los datos de dicho archivo se importarán a una tabla llamada aux.

3) Luego, se deberá ejecutar funciones.sql, donde se crearán todas las funciones necesarias que se usarán
durante el proceso de migración.

4) Luego, se debe ejecutar migracion.sql, que creará la función migracion(), que se encarga de crear la tabla recorrido_final y de migrar los datos a dicha tabla.

5) Para migrar los datos a la tabla recorrido_final, se debe ejecutar la función migracion con el siguiente comando postgresql:
"SELECT migracion()". Esta función, aparte de migrar la información a la tabla recorrido_final, también se encarga de eliminar las tablas auxiliares generadas durante los pasos anteriores.

6) Por último, si se desea agregar un trigger a la tabla recorrido_final, que valide si se está insertando un intervalo solapado, se deberá ejecutar trigger.sql, que creará y asignará dicho trigger a la tabla.
