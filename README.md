# INFORME TÉCNICO: EVALUACIÓN PARCIAL N°3
## Gestión Avanzada del Estado y Ciclo de Vida de Recursos en Terraform

**Asignatura:** Infraestructura como Código II (AUY1105)  
**Ponderación:** 30% / Modalidad Ejecución Práctica Individual  
**Estudiante:** Eduardo Urbina  
**Docente:** Valentina Muñoz  
**Institución:** Duoc UC  
**Fecha:** Julio 2026  

---

## 1. Resumen Ejecutivo
El presente informe técnico documenta la resolución práctica de escenarios críticos de contingencia en la nube de Amazon Web Services (AWS) mediante el uso avanzado de la interfaz de línea de comandos (CLI) de Terraform. La continuidad operativa de los paradigmas de Infraestructura como Código (IaC) depende críticamente de la integridad de su base de datos de estado (`terraform.tfstate`). 

A través de esta ejecución, se simularon y mitigaron tres problemáticas comunes de alta complejidad en entornos de producción: la pérdida total del registro de estado (Disaster Recovery), la desviación de configuraciones operativas (*Configuration Drift*) y el desacoplamiento quirúrgico de recursos para su transición a esquemas de administración externa o manual.

### 📊 Matriz de Control de Escenarios Operativos
| Dimensión | Desafío Técnico Simulado | Mecanismo de Mitigación | Indicador de Éxito |
| :--- | :--- | :--- | :--- |
| **Escenario 1** | Pérdida catastrófica del archivo `.tfstate` (Desconexión de control). | Reconstrucción inversa mediante jerarquía de dependencias en Zsh. | Mapeo al 100% de la arquitectura sin recreación física. |
| **Escenario 2** | Modificación no autorizada en consola (*Drift*) y degradación de cómputo. | Sincronización bidireccional y aislamiento destructivo controladamente. | Absorción de configuraciones físicas y purga automática de marcas. |
| **Escenario 3** | Exclusión de recursos perimetrales del ciclo de vida automatizado. | Extracción controlada del inventario estatal y refactorización estática. | Persistencia del recurso en la nube y plan local en estado neutro. |

---

## 2. Gobierno de la Infraestructura Base Desplegada
Como punto de partida, se validó y ejecutó el aprovisionamiento de la topología de red y servicios en la región central de AWS `us-east-1` (N. Virginia), utilizando como base de aprovisionamiento el repositorio modularizado del equipo (`AUY1105-grupo-5`). 

### 🧬 Inventario Detallado de Activos Cloud (Línea Base)
La infraestructura desplegada y su codificación correspondiente se estructuraron bajo los siguientes identificadores físicos inequívocos provistos por AWS:

* **VPC Core:** `module.network.aws_vpc.this` ➡️ **ID AWS:** `vpc-0e74ea0052495acba` (Direccionamiento CIDR: `10.1.0.0/16`)
* **Subnets de Acceso Público (Capa Web/Perimetral):**
  * `module.network.aws_subnet.public[0]` ➡️ **ID AWS:** `subnet-031af00d0e417ab6e` (CIDR: `10.1.1.0/24`)
  * `module.network.aws_subnet.public[1]` ➡️ **ID AWS:** `subnet-08ef1bf538a0b0d35` (CIDR: `10.1.2.0/24`)
* **Subnets de Acceso Privado (Capa de Aplicación/Datos):**
  * `module.network.aws_subnet.private[0]` ➡️ **ID AWS:** `subnet-0e7df690623be3f34` (CIDR: `10.1.3.0/24`)
  * `module.network.aws_subnet.private[1]` ➡️ **ID AWS:** `subnet-0d8b4e7278be114ad` (CIDR: `10.1.4.0/24`)
* **Cortafuegos Perimetral (Security Group):** `module.compute.aws_security_group.this` ➡️ **ID AWS:** `sg-0ad3a689a939ad65b` (Reglas iniciales: Inbound TCP/22 y TCP/80)
* **Instancia de Cómputo Elástico:** `module.compute.aws_instance.this` ➡️ **ID AWS Inicial:** `i-03ed871624af40e2c`

---

## 3. Ingeniería de Detalle por Escenario

### 🔹 Escenario 1: Recuperación Catastrófica del Estado de Terraform
Durante la administración rutinaria de arquitecturas complejas, incidentes operacionales o errores humanos pueden derivar en la corrupción o eliminación física del archivo `.tfstate`. En este escenario se simuló la remoción del archivo de estado, provocando que Terraform perdiera la visibilidad sobre los recursos en ejecución en AWS.

#### 1.1 Identificación del Problema e Impacto Operativo
Para aislar y registrar la evidencia, se inició la captura del flujo de la consola mediante el comando `script`:
```bash
script -a escenario1_log.txt
rm terraform.tfstate
Al ejecutar un diagnóstico predictivo (terraform plan) sin base de datos de estado, el motor de Terraform asumió que la nube se encontraba vacía. La herramienta interpretó de manera errónea que debía aprovisionar la totalidad de los componentes desde cero, un evento que en un entorno de producción real causaría interrupciones masivas, colisiones de red y duplicidad de costes.

1.2 Recreación Quirúrgica del Estado con terraform import
Para recuperar el gobierno de la infraestructura sin provocar alteraciones físicas en AWS, se aplicó una estrategia de importación inversa. Se mapearon los recursos existentes asociándolos uno a uno a las declaraciones lógicas del código. Se respetó estrictamente la jerarquía de dependencias, importando primero la VPC raíz antes que los componentes secundarios que se anidan dentro de ella.

Nota de Sintaxis: El uso de comillas dobles o simples es de carácter mandatorio en la arquitectura de la terminal Zsh en macOS para evitar interpretaciones erróneas del shell sobre los índices de arreglos ([0]).

Bash
# Paso 1: Importación de la Red Base (VPC)
terraform import module.network.aws_vpc.this vpc-0e74ea0052495acba

# Paso 2: Importación de Subnets Públicas y sus índices lógicos
terraform import "module.network.aws_subnet.public[0]" subnet-031af00d0e417ab6e
terraform import "module.network.aws_subnet.public[1]" subnet-08ef1bf538a0b0d35

# Paso 3: Importación de Subnets Privadas
terraform import "module.network.aws_subnet.private[0]" subnet-0e7df690623be3f34
terraform import "module.network.aws_subnet.private[1]" subnet-0d8b4e7278be114ad
📷 Evidencia Fotográfica - Escenario 1
La captura de pantalla integrada a continuación demuestra la ejecución secuencial de las importaciones, el procesamiento exitoso por parte de la CLI y la reconstrucción en tiempo real de los metadatos del estado local:

1.3 Verificación y Validación Final
Una vez concluida la inyección de los recursos al mapa estatal, se ejecutó terraform state list para ratificar que la estructura interna se encontraba íntegra. El proceso concluyó con éxito absoluto al ejecutar un nuevo terraform plan, el cual retornó el estado de neutralidad: No changes. Your infrastructure matches the configuration.

🔹 Escenario 2: Actualización ante Desviaciones de Configuración (Drift) y Reforzamiento
Las modificaciones manuales realizadas en las consolas de los proveedores de nube desalinean la realidad operativa respecto a las definiciones del código fuente, un fenómeno conocido como Configuration Drift.

2.1 Identificación de Inconsistencias
Se introdujeron manualmente dos desviaciones críticas en el entorno AWS:

Modificación de Seguridad: Se inyectó directamente una regla inbound HTTPS (Puerto 443 con origen broad 0.0.0.0/0) en el Security Group sg-0ad3a689a939ad65b, violando la política del código que solo permitía puertos 22 y 80.

Desviación de Infraestructura: Tras un reinicio forzado del entorno AWS Academy Lab, la IP pública asociada a la instancia EC2 cambió dinámicamente de 54.90.205.172 a 44.220.164.40.

Al ejecutar un terraform plan, la herramienta interceptó automáticamente ambos desfases, notificando que el estado real de la nube no guardaba paridad con las plantillas locales.

2.2 Sincronización y Ciclo de Reemplazo con refresh y taint
Para resolver este escenario en conformidad con las mejores prácticas internacionales de arquitectura IaC, se ejecutó el siguiente flujo:

Sincronización del Estado: Se corrió el comando terraform refresh para obligar a Terraform a examinar la API de AWS y actualizar el archivo de estado con las nuevas realidades físicas detectadas (la nueva IP y la regla 443 expuesta).

Marcado de Recurso Degradado: Simulando un escenario de corrupción a nivel de sistema operativo en la instancia de cómputo, se aisló el recurso forzando su reemplazo mediante el comando de contaminación técnica:

Bash
terraform taint module.compute.aws_instance.this
Al generar el plan subsiguiente, Terraform desplegó el operador destructivo -/+ (destroy and then create replacement), indicando de forma explícita que destruiría la instancia marcada y purgaría el Security Group de las reglas no autorizadas.

Bash
# Aplicación y saneamiento automatizado del Drift
terraform apply -auto-approve
📷 Evidencia Fotográfica - Escenario 2
Las siguientes capturas técnicas prueban de manera fehaciente la detección de la intrusión de red dentro de la consola del proveedor AWS, seguida del procesamiento técnico e impacto de reconstrucción en la terminal de administración de Mac M1:

Proceso de saneamiento de infraestructura y despliegue del reemplazo:

2.3 Análisis Técnico del Estado Post-Despliegue
El comando terraform apply completó la operación de manera limpia: Resources: 1 added, 1 changed, 1 destroyed.. La instancia obsoleta (i-03ed871624af40e2c) fue de-provisionada y sustituida automáticamente por el nuevo nodo activo i-0748cbaf1a2947d6d con direccionamiento IP interno 107.23.126.180.

Nota de Respaldo Académico: Tras la culminación del despliegue, se ejecutó preventivamente el comando terraform untaint module.compute.aws_instance.this, obteniendo como respuesta: Error: Resource instance is not tainted. Esto constituye un comportamiento nominal y óptimo: el motor de Terraform consume, procesa y limpia la bandera de taint de forma nativa e independiente durante la ejecución satisfactoria de un ciclo de aprovisionamiento.

🔹 Escenario 3: Desasociación Quirúrgica del Ciclo de Vida de Recursos
En las organizaciones, existen casos de uso de alta complejidad donde ciertos recursos de infraestructura (como Cortafuegos o Almacenamiento persistente) deben ser extraídos de la gestión automatizada de Terraform para integrarse a herramientas de gestión centralizada o administración manual por parte de equipos de SecOps, sin que esto signifique destruirlos físicamente de la nube.

3.1 Exclusión de Inventario mediante state rm
Se inició la recolección de trazas en escenario3_log.txt. Para romper el vínculo entre Terraform y el Security Group sg-0ad3a689a939ad65b sin afectar su operatividad en la nube, se removió de forma aislada del árbol del archivo de estado:

Bash
terraform state rm module.compute.aws_security_group.this
Evidencia en Consola: La CLI retornó la confirmación de aislamiento: ✅ Removed module.compute.aws_security_group.this — Successfully removed 1 resource instance.

3.2 Refactorización Arquitectónica del Código Local
Para evitar que un comando de aprovisionamiento posterior volviera a interpretar la declaración del recurso como una directiva de creación (debido a que seguía escrito en los archivos .tf), se implementaron modificaciones en las plantillas mediante herramientas nativas de flujo de texto de macOS:

Bash
# 1. Purgado del bloque del recurso del Security Group dentro del módulo de cómputo
sed -i '' '/^resource "aws_security_group" "this"/,/^}/d' .terraform/modules/compute/main.tf

# 2. Sustitución de la variable dinámica por la inyección rígida del ID real (Hardcoding)
sed -i '' 's/vpc_security_group_ids = \[aws_security_group\.this\.id\]/vpc_security_group_ids = ["sg-0ad3a689a939ad65b"]/' .terraform/modules/compute/main.tf

# 3. Remoción de las salidas estructuradas de datos dependientes (outputs)
sed -i '' '/^output "security_group_id"/,/^}/d' .terraform/modules/compute/outputs.tf
📷 Evidencia Fotográfica - Escenario 3
A continuación se anexan las evidencias técnicas que demuestran la remoción del código fuente desde la interfaz de desarrollo en VS Code, y la subsecuente consulta de verificación perimetral:

Ejecución del comando predictivo final que confirma el aislamiento total:

3.3 Validación Final de Aislamiento y Persistencia
Para auditar que el recurso persistiera activo en la nube y que Terraform mantuviera neutralidad absoluta frente a él, se ejecutaron las pruebas cruzadas:

Auditoría Externa (AWS CLI): Al consultar directamente el API de Amazon Web Services mediante aws ec2 describe-security-groups --group-ids sg-0ad3a689a939ad65b --output table, el servicio retornó la matriz de red intacta y plenamente operativa.

Auditoría Local (Terraform CLI): Al ejecutar un terraform plan, la terminal validó que no existían discrepancias, retornando un dictamen libre de operaciones de creación o alteración. El Security Group fue externalizado quirúrgicamente de forma exitosa.

4. Conclusiones y Aprendizajes Técnicos Centrales
El Estado como Eje de Verdad: El archivo de estado (.tfstate) representa el núcleo cognitivo de Terraform. Su desvinculación o pérdida accidental rompe el puente de abstracción con los entornos de nube. Comandos de contingencia como terraform import representan el único canal regulado para la recuperación de infraestructuras complejas operativas.

Gobierno y Limitaciones del Refresh: El comando terraform refresh constituye un mecanismo exclusivo de inspección y lectura de la realidad física del proveedor cloud. Este comando actualiza el inventario local, pero carece de la facultad para aplicar correcciones autónomas sobre el código fuente o resolver discrepancias complejas de configuración por sí solo.

Ciclos de Vida Efímeros controlados por Taint: La marca técnica de contaminación (taint) provee un entorno controlado de gestión predictiva para el mantenimiento de arquitecturas de software corruptas o desactualizadas, optimizando la recreación de nodos mediante la lógica estándar de los ciclos de ejecución.

Desacoplamiento Clínico mediante State RM: El uso preciso de terraform state rm dota a los administradores de infraestructura de una capacidad analítica crucial para aislar, migrar o segmentar componentes arquitectónicos sin comprometer la continuidad del servicio o la estabilidad operacional de los recursos en la nube.
