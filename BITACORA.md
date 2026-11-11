
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


PUNTO 3 

1. ¿Qué respondió Terraform en el paso 1 y en qué se diferencia del segundo docker run de la
Fase 1?

Esta vez el terraform hizo la comparación y antes de actuar valido y refresco la imagen y del contenedor, comparo la infraestructura real y como no encontro cambios no hizo nada. 

2. ¿Qué datos guarda el state que no escribieron en main.tf? ¿Para qué los necesita Terraform?

Guarda identificadores del contenedor creados por docker
datos de red asigandos en tiempo de ejecucion
valores por defecto que heredo de docker

Los utiliza para calcular el plan, detectar cambios, destruir en orden.

3. ¿Por qué el cambio de imagen reemplazó el contenedor en lugar de modificarlo? Relaciónenlo con «Infraestructura mutable vs. inmutable».

Un contenedor de Docker se crea a partir de una imagen concreta, identificada por su hash , y Docker no permite cambiarle la imagen a un contenedor existente. Por eso, al pasar de nginx:1.27-alpine a nginx:1.28-alpine, el plan marcó image con # forces replacement y el símbolo -/+ (destroy and then create replacement). Terraform no “actualizó” nginx dentro del contenedor: destruyó web-g1 y creó uno nuevo a partir de la imagen 1.28.

El enfoque inmutable, el servidor no se toca, se reemplaza completo. : si un servidor necesita cambiar, no se cura, se reemplaza por otro idéntico construido desde la definición.

El enfoque mutable habría sido entrar al contenedor y actualizar nginx en sitio. Ese cambio no quedaría en main.tf, el servidor se volvería único (una “mascota”) y acumularía cambios no documentados. Son los mismos problemas que vivieron en la Fase 1 con ClickOps.

4. ¿Cómo cambió serial después del apply y qué creen que representa?

serial pasó de 13 a 18. Es el número de versión del state: Terraform lo incrementa cada vez que escribe cambios en terraform.tfstate.

No subió solo una vez porque Terraform no guarda el state únicamente al final del apply. Lo guarda después de cada operación sobre un recurso, para no perder registro de lo que ya hizo si el proceso se interrumpe a mitad . 

5. Piensen en un proyecto real con bases de datos: ¿qué riesgo habría si este archivo se subiera a Git?

Si el state se sube a Git, cualquiera con acceso al repositorio, o cualquiera si el repo es público, obtiene esas credenciales. Además, quedan en el historial aunque luego se borre el archivo, así que habría que rotar las contraseñas.

Hay un segundo riesgo, operativo. Si cada integrante trabaja con su propia copia del state desde Git, las copias se desactualizan. Un apply con un state viejo puede hacer creer a Terraform que un recurso no existe y recrearlo, o que sobra y destruirlo. Con una base de datos, eso puede significar perder datos.
