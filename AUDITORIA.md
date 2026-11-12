# Auditoría cruzada · Grupo 1 audita al Grupo 3

**Auditores:** Grupo 1 (Manuel Rodríguez, Xiomara Ocampo, Derly Quejada, Luisa Londoño)
**Grupo auditado:** Grupo 3 (Sofía Giraldo González, Carlos Augusto Aranzazu, Miguel Ángel Rodríguez)
**Repositorio auditado:** https://github.com/miguel2607/Arquitectura-IaC (commit `f10ed7a`, fase-9)

## Resultado por anti-patrón

| Anti-patrón | Resultado | Evidencia |
|---|---|---|
| Tocar a mano | Cumple | `BITACORA.md` solo registra comandos de Docker sobre la infraestructura en las fases donde la guía los pide: Fase 1 (ClickOps, líneas 78-109), Fase 4 (drift a propósito, líneas 302, 327 y 359) y Fase 7 (contenedor del backend, línea 560). Todos los demás cambios entraron por código: cambio de imagen en la Fase 3, variables en la Fase 5, módulo en la Fase 6. |
| State sin proteger | Cumple | `git log --all --name-only \| grep tfstate` no devuelve nada en ninguno de los 10 commits. `.gitignore` excluye `.terraform/`, `*.tfstate`, `*.tfstate.*` y `*.tfplan`. Desde la Fase 7 el state vive en PostgreSQL (`backend "pg" {}` en `infra/main.tf:4`), con bloqueo comprobado (`BITACORA.md:596-604`). |
| Copiar y pegar | Cumple | `grep -rn --include='*.tf' docker_container infra/` solo aparece en `infra/modules/sitio_web/main.tf:13` y `outputs.tf:6`. Los siete sitios de los tres ambientes salen de un único `module "sitio"` con `for_each = local.sitios` (`infra/main.tf:16-24`). |
| Secretos en el código | Cumple | `backend "pg" {}` está vacío y la conexión se lee de `PG_CONN_STR`. En la bitácora la contraseña aparece siempre como `****` (`BITACORA.md:555`, `560` y `563`). `git log -p -S <clave>` no devuelve ningún commit, y `git log --all -p \| grep -E "POSTGRES_PASSWORD=[^*]"` tampoco encuentra la clave real. |
| Aplicar sin leer el plan | Cumple (con una excepción) | Casi todos los `apply` tienen su línea `Plan:` y la aprobación del revisor escrita: Fase 2 (`:176`), Fase 3 (`:265`), Fase 4 A y B (`:315`, `:347`), Fase 5 (`:415`), Fase 6 (`:512`), Fase 7 (`:620`, `:646`, `:654`, `:664`) y Fase 9 (`:904`). La excepción es el Experimento C de la Fase 4: `terraform apply -replace=docker_container.web` (`BITACORA.md:366-370`) muestra el plan `1 to add, 0 to change, 1 to destroy`, pero no tiene la frase de aprobación del revisor. |
| Un solo archivo gigante | Cumple | `ls infra` muestra `main.tf`, `variables.tf`, `locals.tf`, `data.tf`, `outputs.tf` y `terraform.tfvars`; el módulo tiene `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf` y `tests/`. El archivo más largo de la raíz (`main.tf`) tiene 24 líneas. |

## Hallazgos concretos

1. **El historial de Git no refleja la rotación de roles.** `git log --format='%h %an %ad'` muestra que los 10 commits son del mismo autor (`Miguel`) y que los nueve de las fases 0 a 8 se hicieron el 2026-11-08 entre las 14:36 y las 14:51, con uno o dos minutos de diferencia. La tabla de rotación (`BITACORA.md:15-25`) asigna el rol de operador a tres personas distintas, pero el repositorio no permite comprobarlo. Esto va contra el beneficio «Auditable» de la clase: con IaC, Git debería dejar claro quién cambió qué y cuándo.
2. **La bitácora tiene huecos en la aprobación de planes y en el cierre.** El `terraform apply -replace=docker_container.web` del Experimento C (`BITACORA.md:366-370`) no tiene la frase de aprobación del revisor, a diferencia de los demás `apply`. En la Fase 9, `BITACORA.md:908` conserva el espacio en blanco `A nosotros nos señalaron: ____________________.` La Parte B (`BITACORA.md:882-904`) solo muestra el `plan -destroy`: no hay salida de `terraform destroy`, ni del `docker ps` que muestra que solo queda `tf-state-g3`, ni de la eliminación del backend.
3. **Código y evidencias con detalles por revisar.** La variable `imagen` de `infra/variables.tf:6-10` no la usa nadie desde la Fase 7, porque `infra/main.tf:23` toma la imagen de `local.amb.imagen`. Además repite el mismo default de `infra/modules/sitio_web/variables.tf:14`. En la prueba de bloqueo (`BITACORA.md:592-601`) la terminal 1 tenía un `terraform apply` abierto, pero la información del bloqueo dice `Operation: OperationTypePlan`, cuando un `apply` normalmente registra `OperationTypeApply`.

## Recomendación

Completar la Fase 9 en este orden: `terraform destroy` en `dev`, `staging` y `prod`, `docker ps` mostrando que solo queda `tf-state-g3` y luego `docker rm -f tf-state-g3`, con las salidas pegadas como texto. En la misma pasada, llenar la respuesta pendiente de `BITACORA.md:908`, agregar la aprobación del revisor al Experimento C y borrar la variable `imagen` de `infra/variables.tf`. Que el commit `fase-9` lo haga, con su propio usuario de Git, quien operó esa fase según la tabla de rotación (Carlos).
