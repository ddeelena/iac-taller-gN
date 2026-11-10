
| Fase | Operador | Navegante | Revisor de plan | Bitacora |
| --- | --- | --- | --- | --- |
| **Fase 1 y 0** | Derly | Xiomara | Luisa | Manuel |
| **Fase 2** | Manuel | Derly | Xiomara | Luisa |
| **Fase 3** | Luisa | Manuel | Derly | Xiomara |
| **Fase 4** | Xiomara | Luisa | Manuel | Derly |
| **Fase 5** | Derly | Xiomara | Luisa | Manuel |
| **Fase 6** | Manuel | Derly | Xiomara | Luisa |
| **Fase 7** | Luisa | Manuel | Derly | Xiomara |
| **Fase 8** | Xiomara | Luisa | Manuel | Derly |
| **Fase 9** | Derly | Xiomara | Luisa | Manuel |


Grupo 1

MANUEL RODRIGUEZ 
XIOMARA OCAMPO
DERLY QUEJADA
LUISA LONDONO

1. ¿Qué error produjo el segundo docker run? ¿Qué dice eso sobre la idempotencia de un
comando imperativo?

Dio error de Bind for 0.0.0.0:8090 failed: port is already allocated

Que si fuera imperativo entonces hubiese comparado si ya existia el contenedor antes de crearlo y no lo hubiese creado y luego teniendo problemas para correrlo. 

2. Si otro grupo necesitara mañana un servidor idéntico, ¿qué tendrían que contarle y dónde
quedó registrado lo que hicieron?

Basado en los errores que nosotros cometimos habria que indicarles la imagen exacta que utilizamos de nginx, que el nombre no lleva espacio antes de -g1, el mapeo de los puertos 8090:80, que recuerden revisa que el puerto este libre y que deben revisar si tienen contenedores con el mismo nombre. 

3. ¿Cuáles de los cuatro puntos de la diapositiva «Por qué duele» vivieron en esta fase?

Lento y propenso a errores humanos: fueron unos 5 intentos para levantar nginx porque hubieron errores de tipeo y dos de conflictso de errores de puertos

Sin historial, nadie sabe quien cambio que: No hay forma de saber quien los creo, con que configuraciones ni si se pueden borrar. Además, al hacer rm-f no dejaron rastro de lo eliminado.

El conocimiento se va con la persona: las correcciones que yo tuve que hacer y que me enseñaron nuevas cosas, se quedan en mi mente y al cambiar de roles ellos no lo sabrán a menos que yo este con ellos e identifique y divulgue esos conocimientos. 

PUNTO 1

1. Pidieron un solo servidor. ¿Cuántos recursos creó el plan y por qué?

El plan inicial creó dos recursos, no uno:

docker_image.nginx descarga y registra la imagen nginx:1.27-alpine.
docker_container.web es el contenedor que corre a partir de esa imagen.

En Terraform la imagen es un recurso independiente porque tiene su propio ciclo de vida: se descarga, tiene un ID  y se puede actualizar o borrar por separado. El “servidor” que se pidio es la suma de los dos.

En nuestro caso, tuvimos que rehacer el plan puesto que teniamos el plan 8080 ocupado con algo de postgrest por lo tanto cambiamos el archivo y rejecutamos todo, entonces al aplicarlo primero destruyo el primero que fallo y luego si lo hizo con el nuevo puerto que era el 8081

2. ¿Qué orden de creación impone docker_image.nginx.image_id?

Crea docker_image.nginx, es decir, descarga la imagen y obtiene su ID.
Crea docker_container.web usando ese ID.

3. ¿Qué descargó terraform init, dónde lo guardó y para qué sirve .terraform.lock.hcl?

Descargo el proveedor kreuzwerker/docker, lo guardo en la carpeta oculta infra\.terraform\, bajo una ruta como providers\registry.terraform.io\kreuzwerker\docker\4.6.0\windows_amd64\. Esa carpeta no se sube a Git; cada persona la regenera con init. Sirve para registra la versión exacta del proveedor.

4. De los cuatro bloques de la diapositiva «Cómo se escribe Terraform», ¿cuál no aparece todavía en su archivo?

Falta variable, lo notamos cuando nos toco cambiar de puerto, y para hacerlo fue directamente en el archivo.

5. Comparen con la Fase 1: ¿dónde quedó registrado ahora lo que hicieron?

En la Fase 1 no quedó registrado en ningún lado más allá del historial de PowerShell. Ahora hay tres lugares:

main.tf: el estado deseado, escrito y legible. Cualquier grupo puede clonarlo, ejecutar terraform apply y obtener el mismo servidor. La corrección del puerto 8080 → 8081 está ahí, no en la memoria de nadie.
.terraform.lock.hcl: la versión exacta de las herramientas usadas.
terraform.tfstate: el estado real, con los IDs de lo que se creó (como el 4387c3145f0b... del contenedor). Gracias a él Terraform sabe qué existe y puede detectar el tainted o calcular que solo hay que reemplazar el contenedor.

Si suben main.tf y el lock file a Git, también queda quién cambió qué y cuándo, que era justo uno de los puntos de «Por qué duele». El propio plan sirve de documentación del cambio: muestra url = "http://localhost:8080" -> "http://localhost:8081" antes de aplicarlo.


