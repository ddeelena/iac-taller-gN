
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

PUNTO 4

SALIDA del plan 




| Experimento | ¿El plan lo detectó? | ¿Qué propuso Terraform? | ¿Cómo quedó corregido? |
|---|---|---|---|
| A · Apagar | Sí. `must_run` pasó de `false` a `true` y el contenedor detenido ya no reportaba sus puertos publicados. | Reemplazar el contenedor (`-/+`): 1 a crear, 0 a cambiar, 1 a destruir. El bloque `ports` fuerza el reemplazo. | `terraform apply` destruyó el contenedor detenido y creó uno nuevo. La página volvió a responder en 8081. |
| B · Borrar | Sí. `plan -refresh-only` informó que `docker_container.web` fue eliminado por fuera de Terraform. | `plan -refresh-only` solo propuso actualizar el state. `terraform plan` propuso crear el contenedor de nuevo: 1 a crear, 0 a cambiar, 0 a destruir. | `terraform apply` recreó `web-g1` desde el código. La página volvió a responder en 8081. |
| C · Cambiar por dentro | No. El plan respondió «No changes», aunque la página mostraba «Cambio manual». | Nada. Para Terraform el contenedor coincidía con el código. | Reemplazo forzado con `terraform apply -replace=docker_container.web`: 1 a crear, 1 a destruir. El contenedor nuevo volvió a mostrar la bienvenida de nginx. |


**1. ¿Por qué Terraform no detectó el experimento C? ¿Qué tipo de herramienta de la diapositiva «Aprovisionar ≠ configurar» se encarga de ese nivel?**

Terraform solo compara los atributos del recurso que el provider le reporta: nombre, imagen, puertos, si está corriendo, etc. El archivo `index.html` vive dentro del sistema de archivos del contenedor, y ningún atributo de `docker_container` lo describe. Desde afuera, el contenedor seguía siendo idéntico al del código: mismo nombre, misma imagen, mismo puerto y corriendo. Por eso el plan respondió «No changes».

Terraform es una herramienta de **aprovisionamiento**: crea y gestiona la infraestructura (que exista un contenedor con cierta imagen y puerto). Lo que pasa dentro del servidor (archivos, paquetes, servicios) lo manejan las herramientas de **gestión de configuración**, como Ansible, Chef o Puppet. Estas sí revisan y corrigen el estado interno de cada máquina.

**2. ¿Por qué `-replace` es una corrección coherente con la infraestructura inmutable?**

Porque no repara el contenedor alterado, lo descarta. Otra opción habría sido entrar con `docker exec` y restaurar el `index.html` a mano. Eso sería el enfoque mutable: modificar el servidor en sitio, sin registro, y dejarlo convertido en una «mascota» con cambios que nadie documentó.

Con `-replace`, Terraform destruye el contenedor y crea uno nuevo exactamente desde el código. Así se garantiza que el servidor vuelva a ser idéntico a lo definido en `main.tf`, sin importar qué se le haya hecho por dentro. Es el principio de la diapositiva: el servidor no se toca, se reemplaza completo.

**3. En un equipo real, ¿cómo detectarían el drift sin esperar a que alguien ejecute `plan` por casualidad?**

- **Plan programado en el pipeline CI/CD:** un trabajo periódico (por ejemplo, cada noche) ejecuta `terraform plan -detailed-exitcode`. Ese comando devuelve el código `2` cuando hay diferencias, y ese código se puede usar para enviar una alerta al equipo (correo, Slack, un issue).
- **Herramientas con detección de drift integrada:** plataformas como HCP Terraform (antes Terraform Cloud) revisan los workspaces automáticamente y avisan cuando la infraestructura real se desvía del state.
- **Prevenir además de detectar:** quitar los permisos para modificar la infraestructura a mano, de modo que los cambios solo puedan entrar por código revisado, y activar registros de auditoría del proveedor para saber quién cambió qué.

Para el nivel que Terraform no ve, como el experimento C, se combina con herramientas de gestión de configuración que verifican periódicamente el contenido de los servidores, o se adopta del todo el modelo inmutable: los contenedores se reemplazan con frecuencia y nadie tiene acceso para modificarlos por dentro.

FASE 5 

Por que se reemplza el contenedor, esto es por que el contenedor tiene dos bloques nuevos y ninguno de ellos se puede agregar si el contenedor ya existe.

En este caso son el upload y los labels, que requieren estar desde la creacion del contenedor. 

1. puerto tiene un default, puede venir de terraform.tfvars y se pasó con -var. ¿Qué valor gana cuando hay varios?

Gana la fuente más específica, que es la que se da más tarde en la ejecución. Terraform aplica este orden, de menor a mayor prioridad:

1. El `default` de la variable (`8080`).
2. Variables de entorno `TF_VAR_puerto`.
3. El archivo `terraform.tfvars` (`8081` en nuestro caso).
4. Archivos `*.auto.tfvars`.
5. Las opciones `-var` y `-var-file` de la línea de comandos (`8085`).

Por eso `terraform plan -var="puerto=8085"` propuso reemplazar el contenedor para publicarlo en el 8085, aunque el `tfvars` dijera 8081. Sin `-var`, gana el `tfvars`. Si el `tfvars` no definiera `puerto`, se usaría el default 8080. El default es un valor de respaldo, `tfvars` es la configuración del grupo y `-var` es un cambio puntual para una sola ejecución.

2. ¿Qué hizo el bloque validation con el puerto 9500? ¿En qué se parece a la idea de Policy as Code?

Detuvo el plan antes de contactar a Docker. Terraform evaluó la condición `var.puerto >= 8000 && var.puerto <= 8999`, vio que 9500 no la cumplía y respondió con nuestro mensaje: *"El puerto debe estar entre 8000 y 8999."* No se calculó ningún plan ni se tocó la infraestructura.

Se parece a Policy as Code porque la regla del equipo ("los sitios usan puertos del rango 8000–8999") no depende de que alguien la recuerde ni de una revisión manual. Está escrita como código, se versiona en Git junto con la infraestructura y se verifica de forma automática en cada ejecución, bloqueando cualquier cambio que la incumpla antes de aplicarlo.

La diferencia es el alcance. `validation` revisa una sola variable dentro de nuestro propio código. Las herramientas de Policy as Code, como OPA o Sentinel, aplican políticas de toda la organización sobre el plan completo y sobre cualquier repositorio; por ejemplo, "ningún bucket público" o "solo estas regiones".


3. ¿Terraform creó la red bridge? ¿Qué le pasará cuando el grupo ejecute destroy?

No. `bridge` es la red por defecto que Docker crea al instalarse, y nosotros la declaramos como **data source** (`data "docker_network" "bridge"`), no como `resource`. Un data source solo **lee** información de algo que ya existe, en este caso su `driver` para el output `red_driver`. Terraform no lo crea, no lo modifica y no lo considera de su propiedad.


Cuando se  ejecute `terraform destroy`, solo se eliminarán los recursos gestionados (el contenedor y la imagen). La red `bridge` seguirá existiendo, porque Terraform nunca la administró. Es el mismo criterio que con la red del salón: se puede consultar y usar, pero no le pertenece a nuestro código.


4. ¿Qué ganan con local.nombre frente a escribir "web-gN" en cada lugar donde se necesita?

- **Una sola fuente de verdad:** el nombre se define una vez (`"web-g${var.grupo}"`) y todos los lugares que lo usan lo leen de ahí. Si la convención cambia, se modifica una línea y no se busca cada aparición.
- **Consistencia y menos errores:** no hay riesgo de que en un lugar diga `web-g1` y en otro `web-gl` o `web-g01` por un error de tipeo.
- **Reutilización:** como se calcula a partir de `var.grupo`, el mismo código sirve para cualquier grupo cambiando solo `terraform.tfvars`. Con `"web-gN"` escrito a mano, cada grupo tendría que editar el código en varios lugares.
- **Legibilidad:** `local.nombre` comunica la intención ("el nombre del servidor") en lugar de un valor literal cuyo origen hay que adivinar.

`PUNTO 6`

El revisor debe explicar qué se destruye, qué se crea y por qué antes de aprobar.

Se destruyen 2 recursos: docker_image.nginx y docker_container.web, porque los quitamos de la raíz. Se crean 6: una imagen y un contenedor por cada módulo (tienda, blog y docs). Terraform no sabe que web-g1 “se convirtió” en la tienda; para él son direcciones distintas, así que borra lo viejo y crea lo nuevo. Aprobado: 6 a crear, 0 a cambiar, 2 a destruir

1. Anoten la línea Plan: del paso 8. ¿Qué se destruyó, qué se creó y por qué?

- **Se destruyeron 2 recursos:** `docker_image.nginx` y `docker_container.web` (el contenedor `web-g1`). Los eliminamos de `infra/main.tf`, pero seguían registrados en el state. Cuando un recurso está en el state y ya no está en el código, Terraform entiende que debe dejar de existir.
- **Se crearon 6 recursos:** cada llamada al módulo crea una imagen y un contenedor, así que fueron `module.tienda`, `module.blog` y `module.docs`, cada uno con su `docker_image.this` y su `docker_container.this`. Los contenedores quedaron como `tienda-g1` (8081), `blog-g1` (8082) y `docs-g1` (8083).

**Por qué:** Terraform identifica cada recurso por su **dirección** en el código, no por lo que hace. Para él, `docker_container.web` y `module.tienda.docker_container.this` son recursos diferentes, aunque la tienda use el mismo puerto 8081 que tenía `web-g1`. Por eso no "movió" el servidor, sino que destruyó el viejo y creó el nuevo. Se podría haber evitado con un bloque `moved` (como propone el reto opcional), que le indica a Terraform que una dirección nueva corresponde a un recurso existente.

Como la imagen se declaró con `keep_locally = true`, destruir `docker_image.nginx` no borró `nginx:1.28-alpine` del equipo. Los tres módulos la reutilizaron sin volver a descargarla.

2. ¿Qué error obtendrían si el módulo no tuviera versions.tf?

`terraform init` fallaría con un error como este:

```text
Error: Failed to query available provider packages

Could not retrieve the list of available versions for provider hashicorp/docker:
provider registry registry.terraform.io does not have a provider named
registry.terraform.io/hashicorp/docker
```

Cuando un módulo usa recursos `docker_*` sin declarar de dónde viene el provider, Terraform asume el espacio de nombres por defecto, `hashicorp/`, y busca `hashicorp/docker`, que no existe. El provider real es `kreuzwerker/docker`. Declararlo en la raíz no basta: cada módulo debe indicar sus propios `required_providers`, porque Terraform resuelve los providers módulo por módulo.

3. Si mañana hay que agregar una etiqueta a todos los sitios, ¿cuántos archivos tocan con módulo?
¿Cuántos bloques habrían tocado copiando y pegando?

- **Con módulo:** un archivo (`modules/sitio_web/main.tf`) y un bloque (`docker_container.this`). El cambio llega automáticamente a los tres sitios en el siguiente `apply`. Si la etiqueta debe variar por sitio, se agrega además una variable en `modules/sitio_web/variables.tf`, que sigue siendo un solo lugar.
- **Copiando y pegando:** tres bloques `docker_container` (tienda, blog y docs), con el riesgo de olvidar uno o escribirlo distinto en cada copia. Además, el costo crece con cada sitio nuevo; con los siete sitios de la Fase 7 serían siete bloques, mientras que con el módulo sigue siendo uno.


4. ¿Qué necesitaría otro grupo para usar su módulo sin copiar la carpeta?

Que el módulo esté publicado en un lugar desde donde Terraform pueda descargarlo, y referenciarlo en su `source`. La opción más directa es nuestro repositorio de Git, apuntando a la subcarpeta y a una versión fija (etiqueta o commit):

```hcl
module "tienda" {
  source  = "git::https://github.com/<usuario>/iac-taller-g1.git//infra/modules/sitio_web?ref=v1.0.0"
  nombre  = "tienda-g2"
  puerto  = 8081
  mensaje = "Tienda del grupo 2"
}
```

Al ejecutar `terraform init`, Terraform descarga el módulo. Para eso, el otro grupo necesitaría:

- **Acceso al repositorio** (público, o con permisos si es privado).
- **Una versión etiquetada** (`ref=v1.0.0`), para que nuestros cambios futuros no les rompan su infraestructura sin aviso.
- **Documentación de la interfaz:** qué variables recibe (`nombre`, `mensaje`, `imagen`, `puerto` y su rango válido) y qué outputs entrega (`url`, `nombre`), idealmente en un `README.md` del módulo.

En equipos más grandes, el módulo se publica en un **registro** (el Terraform Registry público o uno privado de la organización) y se consume con `source` y `version`, como cualquier provider.


`FASE 7`

### Respuestas

**1. ¿Qué respondió la terminal 2 en la prueba de bloqueo? ¿Qué problema de trabajo en equipo evita?**

```text
<pegar aquí la salida de terraform plan en la terminal 2>
```

La terminal 2 respondió `Error acquiring the state lock`, con la información del bloqueo: quién lo tiene, desde cuándo y qué operación lo tomó (`OperationTypeApply`). Mientras la terminal 1 tenía un `apply` abierto esperando confirmación, el backend PostgreSQL mantenía el state bloqueado, y ninguna otra operación podía leerlo ni escribirlo. Al responder `no` en la terminal 1, el bloqueo se liberó y la terminal 2 pudo planear normalmente.

Evita que dos personas apliquen cambios sobre el mismo state al mismo tiempo. Sin bloqueo, ambas partirían de la misma versión del state y la última en escribir sobrescribiría el trabajo de la otra. El resultado sería un state que ya no refleja la infraestructura real: recursos huérfanos que Terraform no sabe que existen, o recursos que cree tener y ya no están. Con el bloqueo, los cambios sobre un mismo ambiente se aplican de uno en uno.

**2. ¿Dónde quedó la contraseña del backend y por qué no debe estar en `main.tf`?**

La contraseña quedó solo en dos lugares fuera del repositorio:

- en la variable de entorno `PG_CONN_STR` de la terminal donde se definió, que desaparece al cerrarla;
- en la configuración del contenedor `tf-state-g1`.

En `main.tf` el backend está declarado vacío (`backend "pg" {}`), y Terraform completa la conexión leyendo `PG_CONN_STR` en el momento de ejecutarse. `git grep <clave>` no encuentra nada en el repositorio, y en esta bitácora la clave aparece reemplazada por `<clave>`.

No debe estar en `main.tf` porque ese archivo se versiona. Todo lo que entra a un commit queda en el historial de Git para siempre, aunque después se borre, y lo puede leer cualquiera con acceso al repositorio (todos, si es público). Además, quien tiene la contraseña del backend tiene acceso al state de todos los ambientes, que contiene detalles de la infraestructura y, en proyectos reales, otros secretos. Separar la credencial del código también permite cambiarla, o usar una distinta por persona o por ambiente, sin tocar ni volver a revisar el código.

**3. ¿Qué filas tiene ahora la tabla `states` y cómo se relacionan con los workspaces?**


La tabla tiene cuatro filas: `default`, `dev`, `staging` y `prod`. Cada workspace de Terraform corresponde a una fila, y cada fila guarda un state completo e independiente. Al cambiar de workspace con `terraform workspace select`, Terraform lee y escribe la fila correspondiente. Por eso los tres ambientes comparten el mismo código y el mismo backend, pero cada uno lleva su propio registro de lo que creó: un `apply` en `dev` no ve ni puede modificar los recursos de `prod`.

La fila `default` sigue existiendo porque es el workspace inicial al que se migró el state en el paso 4. Después de `terraform destroy` quedó vacía de recursos, pero no se elimina.

**4. ¿Qué error da `terraform plan` en el workspace `default` y por qué es útil que falle?**



El error es `Invalid index` en `local.ambientes[local.entorno]`, porque el mapa `ambientes` solo tiene las llaves `dev`, `staging` y `prod`. En el workspace `default`, `terraform.workspace` vale `"default"`, que no corresponde a ningún ambiente, así que Terraform no puede calcular `local.amb` y el plan se detiene antes de contactar a Docker.

Es útil porque obliga a elegir un ambiente de forma explícita. Si el código tuviera un valor por defecto, alguien podría ejecutar `apply` sin darse cuenta de en qué workspace está y crear o modificar infraestructura en un lugar no previsto. Es un fallo seguro (*fail fast*): el error ocurre antes de causar daño, y su mensaje indica exactamente qué falta.

**5. ¿Por qué `dev` tiene un solo sitio y `staging` replica a `prod`? ¿Por qué `prod` usa otra versión de imagen?**

Cada ambiente tiene un propósito distinto:

- **`dev`** es el lugar para desarrollar y probar rápido. Solo necesita lo indispensable (la tienda) para comprobar que los cambios funcionan, consumiendo menos recursos, que en la nube también significa menos costo.
- **`staging`** es la prueba final antes de producción, y por eso debe ser lo más parecido posible a `prod`: los mismos tres sitios. Si un cambio funciona en un `staging` idéntico a `prod`, hay alta confianza de que funcionará en producción. Si `staging` fuera más pequeño, se podrían escapar problemas que solo aparecen con todos los componentes juntos.
- **`prod`** usa `nginx:1.27-alpine` mientras `dev` y `staging` prueban `nginx:1.28-alpine`. Es una **promoción controlada**: la versión nueva primero se valida en los ambientes de prueba, y solo cuando `staging` demuestra que funciona se cambia el valor de `prod`. Así un error de la versión nueva afecta a los ambientes de prueba y no a los usuarios reales.

**6. Los tres ambientes comparten código y backend. ¿Qué riesgo tiene eso frente a usar carpetas separadas por ambiente?**

- **Equivocarse de workspace:** el ambiente activo no se ve en los archivos, solo en el comando `terraform workspace show`. Es fácil ejecutar `apply` en `prod` creyendo estar en `dev`. Con carpetas separadas, el ambiente es evidente por la ruta donde se trabaja.
- **Un cambio afecta a todos los ambientes:** como el código es uno solo, cualquier modificación se aplicará a `prod` en su siguiente `apply`, aunque solo se haya querido probar en `dev`. Las diferencias entre ambientes deben expresarse con condiciones o mapas (como `local.ambientes`), lo que hace el código más complejo.
- **Mismo acceso para todo:** con un solo backend y una sola credencial, quien puede modificar `dev` también puede leer y modificar el state de `prod`. Con carpetas o backends separados, se puede restringir el acceso a producción a menos personas.
- **Radio de impacto mayor:** un error en el backend compartido, ya sea el contenedor caído, una base de datos dañada o un bloqueo atascado, afecta a los tres ambientes a la vez.

Las carpetas separadas tienen su propio costo: más duplicación y riesgo de que los ambientes se desalineen con el tiempo. En la práctica, los riesgos de los workspaces se reducen con un pipeline CI/CD que fija el ambiente en cada ejecución, con revisión obligatoria del plan antes de aplicar en `prod` y, en equipos grandes, con un backend o credenciales separadas para producción.

`PUNTO 8 `

En el primer chequeo de seguridad fallaron 

CKV2_AWS_6 CKV_AWS_145 CKV_AWS_21  CKV_AWS_144 CKV_AWS_18  CKV2_AWS_61 CKV2_AWS_62 CKV_AWS_56 CKV_AWS_55 CKV_AWS_54 CKV_AWS_53

en el segundo fallaron 

CKV2_AWS_62 CKV_AWS_18 CKV2_AWS_61 CKV_AWS_144 CKV_AWS_145 CKV_AWS_21


### Respuestas

**1. ¿Qué encontró cada nivel (estático, pruebas, seguridad) que los otros no podían encontrar?**

- **Análisis estático (`fmt -check` y `validate`):** encontró problemas en el *texto* del código sin ejecutar nada. La primera ejecución de `validar.sh` se detuvo en `fmt -check` y señaló seis archivos con formato incorrecto (`locals.tf`, `main.tf`, `terraform.tfvars` y tres del módulo), y en la Prueba A detectó la indentación desordenada de `outputs.tf`. `validate` revisa sintaxis, tipos y referencias, por ejemplo una variable mal escrita. Ninguno de los otros niveles mira el formato. Este es además el nivel más rápido y barato: no necesita a Docker ni al provider.
- **Pruebas (`terraform test`):** encontraron problemas de *comportamiento*, que solo aparecen cuando el código se evalúa con valores concretos. Verificaron que la URL corresponde al puerto, que la validación rechaza el 9500, que el output `nombre` coincide con la variable y, con `despliegue_real`, que el contenedor se crea de verdad en Docker con el nombre esperado. Un código puede estar bien formateado y ser válido, y aun así producir una URL equivocada o fallar al crearse; eso solo lo descubren las pruebas.
- **Seguridad (`checkov`):** encontró configuraciones *inseguras* que son perfectamente válidas y funcionales. El bucket con los cuatro valores en `false` pasa `fmt`, pasa `validate` y se crearía sin errores, pero queda expuesto públicamente. En la Prueba B, `validar.sh` superó los tres primeros niveles y solo checkov lo detuvo. Los otros niveles comprueban que el código funcione; este comprueba que cumpla las políticas de seguridad.

**2. ¿Qué vio quien observaba `docker ps` durante `despliegue_real`? ¿Por qué vale la pena un entorno desechable?**

Durante las pruebas `plan` no cambió nada en `docker ps`. Al llegar a `despliegue_real` apareció un contenedor nuevo, `prueba-g1`, con `nginx:1.28-alpine` en el puerto 8999, junto a los siete sitios de los ambientes y el backend. Al terminar las pruebas, en la fase de *tearing down*, Terraform lo destruyó automáticamente y `docker ps` volvió a mostrar solo los siete sitios y `tf-state-g1`.

Vale la pena porque permite probar el comportamiento real, creando infraestructura de verdad, sin poner en riesgo los ambientes existentes:

- **Aislamiento:** `terraform test` usa un state temporal propio, distinto del backend PostgreSQL, así que la prueba no puede modificar ni destruir `dev`, `staging` o `prod`.
- **Limpieza automática:** lo creado se destruye al terminar, sin dejar contenedores huérfanos ni, en la nube, recursos generando costos.
- **Repetible:** cada ejecución parte de cero, así que el resultado no depende de restos de pruebas anteriores. Por eso las pruebas pueden correr en cada cambio dentro de un pipeline.

**3. ¿Qué controles fallaron en el bucket y cuántos quedaron después de corregir? ¿Cuáles de ellos corresponden al ejemplo «sin buckets públicos» de la clase?**

| Escaneo | Passed | Failed |
|---|---|---|
| Antes (cuatro valores en `false`) | `<n>` | `<n>` |
| Después (cuatro valores en `true`) | `<n>` | `<n>` |

Controles que fallaron en el primer escaneo: `<lista de IDs, por ejemplo CKV_AWS_53, CKV_AWS_54, CKV_AWS_55, CKV_AWS_56, CKV_AWS_18, CKV_AWS_21, CKV_AWS_145...>`

Al corregir los cuatro valores dejaron de fallar los cuatro controles de acceso público, que son los que corresponden al ejemplo «sin buckets públicos»:

- **CKV_AWS_53:** bloquear ACLs públicas (`block_public_acls`).
- **CKV_AWS_54:** bloquear políticas públicas (`block_public_policy`).
- **CKV_AWS_55:** ignorar ACLs públicas existentes (`ignore_public_acls`).
- **CKV_AWS_56:** restringir buckets públicos (`restrict_public_buckets`).

Los fallos restantes no tienen que ver con el acceso público, sino con otras buenas prácticas: versionado, registro de accesos, cifrado con KMS, entre otros. Por eso `validar.sh` aplica solo los controles 53 a 56 con `--check`: es la política que el equipo decidió hacer obligatoria. Exigir todos los controles haría fallar el pipeline siempre, aunque el bucket ya no sea público. En una nube real, esos controles restantes también habría que atenderlos.

**4. ¿Qué ventaja tiene detectar un problema en el código, antes del `apply`, frente a detectarlo en la nube?**

- **No hay exposición:** si el bucket público se detecta en el código, nunca llega a existir. Si se detecta en la nube, ya estuvo expuesto algún tiempo, y unos minutos bastan para que bots automatizados lo encuentren y extraigan datos. Un dato filtrado no se puede "desfiltrar".
- **Es más barato y rápido de corregir:** en el código basta con cambiar una línea y volver a ejecutar `validar.sh` en segundos. En la nube hay que investigar el incidente, corregir, aplicar de nuevo y quizás notificar a los afectados.
- **No afecta a los usuarios ni genera costos:** un error en el código no provoca caídas del servicio ni recursos mal configurados que se cobran mientras existen.
- **Retroalimentación inmediata:** quien escribió el cambio recibe el error mientras todavía tiene el contexto, no días después cuando una auditoría lo descubre.

Es la idea de *shift left*: mover la detección de problemas lo más temprano posible en el ciclo, donde su costo es menor.

**5. ¿En qué paso del pipeline de la diapositiva va `validar.sh` y qué paso humano viene después?**

El pipeline de la diapositiva tiene cuatro pasos: **Commit → Validar → Revisar → Aplicar**. `validar.sh` corresponde al paso **«Validar»**: se ejecuta automáticamente después de que el cambio entra al repositorio con un commit y antes de que cualquier persona lo revise. Encadena el análisis estático (`fmt -check` y `validate`), las pruebas (`terraform test`) y el escaneo de seguridad (`checkov`), y se detiene en el primer fallo, igual que un pipeline de CI que bloquea el cambio. Su mensaje final lo dice: *"el cambio puede pasar a revisión"*.

El paso humano que viene después es **«Revisar»**. Una persona lee el `terraform plan` (qué se crea, qué cambia y qué se destruye) y decide si aprueba el cambio, normalmente en un *pull request*. Solo con esa aprobación se pasa a **«Aplicar»**, donde se ejecuta el `apply`. Es el mismo rol que cumplió el revisor del plan en este taller.

La división tiene sentido. La validación automática filtra los errores que una máquina puede detectar: formato, comportamiento y políticas de seguridad. Así el revisor no pierde tiempo en ellos y se concentra en lo que requiere criterio humano: si el cambio tiene sentido y si su impacto, por ejemplo un `-/+` en producción, es aceptable.