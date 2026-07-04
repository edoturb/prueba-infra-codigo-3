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
Antes de iniciar los escenarios, se verificó y desplegó la infraestructura base usando el código Terraform del repositorio del grupo (`AUY1105-grupo-5`). Los recursos desplegados en AWS `us-east-1` fueron:
<img width="396" height="122" alt="image" src="https://github.com/user-attachments/assets/60a52d6f-e410-4031-9b15-5d506f8a0961" />


* **VPC Core:** `module.network.aws_vpc.this` ➡️ **ID AWS:** `vpc-0e74ea0052495acba` (CIDR: `10.1.0.0/16`)
* **Subnet Pública [0]:** `module.network.aws_subnet.public[0]` ➡️ **ID AWS:** `subnet-031af00d0e417ab6e`
* **Subnet Pública [1]:** `module.network.aws_subnet.public[1]` ➡️ **ID AWS:** `subnet-08ef1bf538a0b0d35`
* **Subnet Privada [0]:** `module.network.aws_subnet.private[0]` ➡️ **ID AWS:** `subnet-0e7df690623be3f34`
* **Subnet Privada [1]:** `module.network.aws_subnet.private[1]` ➡️ **ID AWS:** `subnet-0d8b4e7278be114ad`
* **Security Group Base:** `module.compute.aws_security_group.this` ➡️ **ID AWS:** `sg-0ad3a689a939ad65b`
* **Instancia EC2 Inicial:** `module.compute.aws_instance.this` ➡️ **ID AWS Inicial:** `i-03ed871624af40e2c`
<img width="396" height="179" alt="image" src="https://github.com/user-attachments/assets/dad3710f-c8c9-47b4-85d0-4eb1b0ba069e" />


---

## 3. Ingeniería de Detalle por Escenario

### 🔹 Escenario 1: Recuperación Catastrófica del Estado de Terraform
Durante la administración rutinaria de arquitecturas complejas, errores humanos pueden derivar en la eliminación física del archivo `.tfstate`. En este escenario se simuló la remoción del archivo de estado, provocando que Terraform perdiera la visibilidad sobre los recursos en ejecución en AWS.

#### 1.1 Identificación del Problema e Impacto Operativo
Para aislar y registrar la evidencia, se inició la captura del flujo de la consola mediante el comando `script`:
```bash

script -a escenario1_log.txt
rm terraform.tfstate
Al ejecutar un diagnóstico predictivo (terraform plan) sin base de datos de estado, el motor de Terraform asumió que la nube se encontraba vacía. La herramienta interpretó de manera errónea que debía aprovisionar la totalidad de los componentes desde cero, un evento que en un entorno de producción real causaría interrupciones masivas.
<img width="396" height="122" alt="image" src="https://github.com/user-attachments/assets/5cc453b8-aa1d-48de-913f-1ebc69c542c5" />


1.2 Recreación Quirúrgica del Estado con terraform import
Para recuperar el gobierno de la infraestructura sin provocar alteraciones físicas en AWS, se aplicó una estrategia de importación inversa. Se mapearon los recursos existentes asociándolos uno a uno a las declaraciones lógicas del código. Se respetó estrictamente la jerarquía de dependencias, importando primero la VPC raíz antes que los componentes secundarios:


VPC:
<img width="396" height="179" alt="image" src="https://github.com/user-attachments/assets/ae127b37-0409-4c46-b32d-2a34d64d5420" />

Subnet Pública:
<img width="396" height="228" alt="image" src="https://github.com/user-attachments/assets/2784b4b3-e720-4e86-922f-8975ec6b7db5" />
Internet Gateway:
<img width="396" height="94" alt="image" src="https://github.com/user-attachments/assets/4b644c63-7023-4019-bcf4-bd51730d83b6" />

Route Table:
<img width="396" height="87" alt="image" src="https://github.com/user-attachments/assets/10769e7a-46e3-47e4-a97f-ec93258dcab9" />

Route (Internet):
<img width="396" height="127" alt="image" src="https://github.com/user-attachments/assets/b2777b47-e833-48ac-a5ca-8a8c5b9e7fc9" />

Security Group:
<img width="396" height="149" alt="image" src="https://github.com/user-attachments/assets/a2eacc7e-87ce-431f-ac58-8654fa2ea5e1" />

EC2 Instance:
<img width="396" height="165" alt="image" src="https://github.com/user-attachments/assets/9669cd1a-4c97-44b4-925e-f7cfa73e42a4" />

S3 Bucket:
<img width="396" height="137" alt="image" src="https://github.com/user-attachments/assets/02f05f00-c6e8-40aa-869b-1567045cfd02" />

Resumen de Mensajes de Éxito de la Importación:
<img width="396" height="201" alt="image" src="https://github.com/user-attachments/assets/65031032-574a-43c9-8d1c-540c2ae21ff9" />

1.3 Verificación y Validación Final del Estado Recreado
Una vez concluida la inyección de los recursos al mapa estatal, se ejecutó terraform state list para ratificar que la estructura interna se encontraba íntegra.
<img width="396" height="179" alt="image" src="https://github.com/user-attachments/assets/4cc91035-18e2-4423-99a1-0385b926c5ee" />


Se inspeccionaron los atributos de recursos clave con el comando terraform state show:
<img width="396" height="155" alt="image" src="https://github.com/user-attachments/assets/bcbf5cd2-3410-4adf-b29f-3c59bfaaa277" />


El proceso concluyó con éxito absoluto al ejecutar un nuevo terraform plan, el cual retornó el estado de neutralidad: No changes. Your infrastructure matches the configuration.
<img width="396" height="155" alt="image" src="https://github.com/user-attachments/assets/8f855db1-cb18-4141-96b0-aff0828ea7ac" />
<img width="396" height="304" alt="image" src="https://github.com/user-attachments/assets/71b1f822-af9c-481f-a6f0-a648a5042f23" />

🔹 Escenario 2: Actualización ante Desviaciones de Configuración (Drift) y Reforzamiento
Las modificaciones manuales realizadas en las consolas de los proveedores de nube desalinean la realidad operativa respecto a las definiciones del código fuente, un fenómeno conocido como Configuration Drift.
<img width="396" height="332" alt="image" src="https://github.com/user-attachments/assets/146c36c1-62b2-42cb-9e2a-4fd7cc990c7a" />


2.1 Identificación de Inconsistencias
Se introdujeron manualmente dos desviaciones críticas en el entorno AWS:
<img width="396" height="112" alt="image" src="https://github.com/user-attachments/assets/d7bf9e9f-eeff-49c4-93fb-81d8b9b197d1" />
<img width="396" height="25" alt="image" src="https://github.com/user-attachments/assets/f607801e-20ec-48a1-924f-36dd004b6c85" />


Modificación de Seguridad: Se inyectó directamente una regla inbound HTTPS (Puerto 443) en el Security Group sg-0ad3a689a939ad65b.

Desviación de Infraestructura: Tras un reinicio forzado del entorno AWS Academy Lab, la IP pública asociada a la instancia EC2 cambió dinámicamente.
<img width="396" height="278" alt="image" src="https://github.com/user-attachments/assets/379d3ce1-5072-41b7-b9a5-bb64f843e6b9" />

<img width="396" height="385" alt="image" src="https://github.com/user-attachments/assets/2a9d3214-0281-41da-8bc0-ccc89a6bcabf" />

Al ejecutar un terraform plan, la herramienta interceptó automáticamente ambos desfases, notificando que el estado real de la nube no guardaba paridad con las plantillas locales.

2.2 Sincronización con terraform refresh
Se ejecutó el comando terraform refresh para obligar a Terraform a examinar la API de AWS y actualizar el archivo de estado con las nuevas realidades físicas detectadas (la nueva IP y la regla 443 expuesta).

2.3 Reforzamiento con terraform taint
Simulando un escenario de corrupción a nivel de sistema operativo en la instancia de cómputo, se aisló el recurso forzando su reemplazo mediante el comando de contaminación técnica:

Bash
terraform taint module.compute.aws_instance.this
Al generar el plan subsiguiente, Terraform desplegó el operador destructivo -/+ (destroy and then create replacement), indicando de forma explícita que destruiría la instancia marcada y purgaría el Security Group de las reglas no autorizadas.

Se aplicaron los cambios de manera limpia:

Bash
terraform apply -auto-approve
2.4 Validación Final y Limpieza
Al ejecutar terraform untaint, Terraform indicó que el recurso no estaba tainted — comportamiento completamente nominal y óptimo: el motor de Terraform consume, procesa y limpia la bandera de taint de forma nativa de forma exitosa.

🔹 Escenario 3: Desasociación Quirúrgica del Ciclo de Vida de Recursos
En las organizaciones, existen casos de uso donde ciertos recursos de infraestructura deben ser extraídos de la gestión automatizada de Terraform, sin que esto signifique destruirlos físicamente de la nube.
<img width="396" height="134" alt="image" src="https://github.com/user-attachments/assets/0b1f7641-80ca-4a16-940a-236553ae8787" />


3.1 Identificación de Recursos a Desasociar
Se listaron los recursos actualmente gestionados por Terraform:
<img width="396" height="134" alt="image" src="https://github.com/user-attachments/assets/c0645917-56fe-4703-a652-6e686538b1b8" />


Bash
terraform state list
3.2 Eliminación del Security Group del Estado
Para romper el vínculo entre Terraform y el Security Group sg-0ad3a689a939ad65b sin afectar su operatividad en la nube, se removió de forma aislada del archivo de estado:
<img width="396" height="134" alt="image" src="https://github.com/user-attachments/assets/5b9c0ce7-d5ad-405c-871c-d8cbfe0c19e5" />

Bash
terraform state rm module.compute.aws_security_group.this
Se verificó mediante un nuevo listado que el recurso ya no figuraba en el control de estado de Terraform.

3.3 Eliminación del Bloque del Código Terraform
Se editó el archivo de configuración para eliminar el bloque resource "aws_security_group" y se reemplazó la variable dinámica en la instancia EC2 por su valor estático (hardcoded). También se removió la salida estructurada (output).
<img width="396" height="122" alt="image" src="https://github.com/user-attachments/assets/80221609-05df-493c-af49-e70478682ecc" />

3.4 Validación de Infraestructura y Persistencia
Para auditar que el recurso persistiera activo en la nube y que Terraform mantuviera neutralidad absoluta frente a él, se ejecutaron las pruebas cruzadas utilizando AWS CLI:
<img width="396" height="319" alt="image" src="https://github.com/user-attachments/assets/9e0a0557-ca51-4a36-9347-2d097f4d2b16" />

Al ejecutar un terraform plan, la terminal validó que no existían discrepancias, retornando un dictamen de "No changes", confirmando que el Security Group fue externalizado quirúrgicamente de forma exitosa.

4. Conclusiones y Aprendizajes Técnicos Centrales
El Estado como Eje de Verdad: El archivo de estado (.tfstate) representa el núcleo cognitivo de Terraform. Su desvinculación accidental rompe el puente de abstracción con los entornos de nube. terraform import representa el único canal regulado para la recuperación de infraestructuras complejas operativas.

Gobierno y Limitaciones del Refresh: El comando terraform refresh constituye un mecanismo exclusivo de inspección y lectura de la realidad física del proveedor cloud. Actualiza el inventario local, pero carece de la facultad para aplicar correcciones autónomas sobre el código fuente.

Ciclos de Vida Efímeros controlados por Taint: La marca técnica de contaminación (taint) provee un entorno controlado de gestión predictiva para el mantenimiento de arquitecturas de software corruptas o desactualizadas, optimizando la recreación de nodos.

Desacoplamiento Clínico mediante State RM: El uso preciso de terraform state rm dota a los administradores de infraestructura de una capacidad analítica crucial para aislar componentes arquitectónicos sin comprometer la continuidad del servicio o la estabilidad de los recursos en la nube.
