# Plan y Documento de Pruebas - Portal Editorial UTALCA

Este documento detalla el plan de pruebas, los casos de uso principales, el listado de libros validados en base de datos y la fórmula de integración con SAP para el Portal Editorial de la Universidad de Talca.

---

## 1. Resumen de Reglas de Negocio para Descuentos
De acuerdo a las validaciones de base de datos implementadas en `vec_cob03.venta_online`:
1. **Comunidad UTalca (Interno)**: Se aplica un **30% de descuento** (`v_factor = 0.7`).
   - Identificado mediante la función `venta_online.get_esutalca(p_rut)`.
   - Incluye a funcionarios (`REM_FICHA`) y estudiantes activos (`alumno`).
   - **RUT de prueba de ejemplo (Funcionario)**: `15318220-5` (Jaime Andrés Venegas).
2. **Público General (Externo)**: Se aplica un **10% de descuento** (`v_factor = 0.9`).
   - Cualquier persona que no pertenezca a la comunidad universitaria.
   - **RUT de prueba de ejemplo (Externo)**: `12345678-9`.

---

## 2. Reporte de Calidad del Código: Bug Crítico en `get_esutalca` (RESOLVIDO)
> [!NOTE]
> **Bug de Clasificación de Estudiantes Activos: CORREGIDO**
> En la función compilada `venta_online.get_esutalca`, el subquery que consulta a la tabla `alumno` realizaba la siguiente concatenación:
> ```sql
> select to_char(a.alu_rut_n||''-''||a.alu_rut_v) Rut
> ```
> Debido al uso de dos comillas simples consecutivas (`''-''`) en lugar de comillas simples simples (`'-'`) dentro del cuerpo de la función compilada original, Oracle evaluaba la expresión como:
> `(alu_rut_n || NULL) - (NULL || alu_rut_v)`
> Esto resultaba en la substracción de valores y luego la concatenación del dígito verificador, haciendo que **para cualquier estudiante, la función retornara únicamente su dígito verificador (por ejemplo, '2') en lugar del RUT completo**.
> 
> **Estado del Bug**: **CORREGIDO**
> El código fue corregido localmente en [VENTA_ONLINE.sql](file:///home/jaime/Documentos/Proyectos/Portal%20Editorial/VENTA_ONLINE.sql) y [VENTA_ONLINE2.sql](file:///home/jaime/Documentos/Proyectos/Portal%20Editorial/VENTA_ONLINE2.sql), y fue compilado exitosamente en la base de datos de QA.
> 
> **Solución aplicada**:
> Se eliminó el formateo erróneo de la concatenación, implementando una limpieza robusta del RUT recibido (`p_rut`), extrayendo el número base de RUT (removiendo el dígito verificador y puntos) y comparándolo directamente con los números base de RUT de funcionarios (`rol_emp`) y alumnos (`alu_rut_n`).
> 
> El código corregido es:
> ```sql
> -- Limpieza del RUT de entrada (remueve guión, DV y puntos)
> v_rut_clean := regexp_replace(p_rut, '-[0-9kK]$', '');
> v_rut_clean := replace(v_rut_clean, '.', '');
> 
> select count(*) into v_encontro from (
>     SELECT to_char(rol_emp) as rut
>     FROM REM_FICHA
>     union
>     select to_char(a.alu_rut_n) as rut
>     from alumno a,  plan_alu p
>     where a.alu_rut_n = p.alu_rut_n
>     and hist_situacion.situacion_valida_informes(pal_situacion_academica_actual) ='S'
>     and pal_situacion_academica_actual  in (1,4,19,30,31,32,72)
> )
> where rut= v_rut_clean;
> ```
> 
> **Resultado de la Verificación Post-Corrección**:
> * `get_esutalca('15318220-5')` (Funcionario) -> **True**
> * `get_esutalca('15318220')` (Funcionario) -> **True**
> * `get_esutalca('8861499-2')` (Estudiante) -> **True**
> * `get_esutalca('8861499')` (Estudiante) -> **True**
> * `get_esutalca('12345678-9')` (Externo) -> **False**

---

## 3. Listado de Libros Validados en la Base de Datos (QA)
A continuación se detallan los libros de la lista proporcionada que **existen en la base de datos** y tienen un precio válido (mayor a $0). Estos libros son aptos para las pruebas.

### 3.1. Libros Aptos para Pruebas (Con Precio Registrado)
| Código SAP (Material) | Título de Material en BD | Precio Base (Catálogo) | Precio Comunidad (30% desc, factor 0.7) | Precio Público (10% desc, factor 0.9) | Estado en BD |
| :--- | :--- | :---: | :---: | :---: | :---: |
| `900000976` | LA COLA DEL DRAGÓN  NO FICCIONES | $15,000 | $10,500 | $13,500 | Activo |
| `900001497` | ¡Viva la ciencia! | $10,000 | $7,000 | $9,000 | Activo |
| `900001498` | FEDERICO ALBERT PIONERO DEL DESARROLLO FORESTAL EN CHILE; FERNANDO HARTWING | $15,000 | $10,500 | $13,500 | Activo |
| `900001503` | Modelamiento de Datos y el Modelo Entidad-Relación | $8,000 | $5,600 | $7,200 | Activo |
| `900001509` | Oclusión para el tratamiento odontológico integral. Teoría y práctica | $10,000 | $7,000 | $9,000 | Activo |
| `900001514` | Por qué cantan los pájaros y otros cuentos | $15,000 | $10,500 | $13,500 | Activo |
| `900001515` | Antología Personal | $15,000 | $10,500 | $13,500 | Activo |
| `900001519` | Poesía fundamental | $20,000 | $14,000 | $18,000 | Activo |
| `900001522` | El gusto de criticar | $20,000 | $14,000 | $18,000 | Activo |
| `900001528` | La Iglesia Católica en el Maule | $20,000 | $14,000 | $18,000 | Activo |
| `900001536` | Universum, Tomo I y II | $40,000 | $28,000 | $36,000 | Activo |
| `900001545` | Sinceridad. Chile íntimo en 1910 | $14,000 | $9,800 | $12,600 | Activo |
| `900001547` | Qué culpa tengo yo. Breve antología personal | $20,000 | $14,000 | $18,000 | Activo |
| `900001548` | Escrito en Rokha. Antología poética de Pablo de Rokha | $20,000 | $14,000 | $18,000 | Activo |
| `900001553` | Ídem | $14,000 | $9,800 | $12,600 | Activo |
| `900001556` | Pacto de Sangre | $12,000 | $8,400 | $10,800 | Activo |
| `900001557` | Río Loa. Estación de los sueños | $15,000 | $10,500 | $13,500 | Inactivo |
| `900001559` | Manuel Larraín. Evocaciones, cartas y discursos | $10,000 | $7,000 | $9,000 | Activo |
| `900001560` | Humanidad y Fé. Monseñor Carlos González Cruchaga. Homenaje en sus sesenta años de sacerdocio. | $15,000 | $10,500 | $13,500 | Activo |
| `900001564` | Juan Ignacio Molina y sus obras Tapa Dura | $18,000 | $12,600 | $16,200 | Activo |
| `900001567` | Homenaje a Oreste Plath (1907-1996). Una vida dedicada a Chile | $15,000 | $10,500 | $13,500 | Activo |
| `900001571` | El Corregidor de Padilla. Entre furias y nieblas | $12,000 | $8,400 | $10,800 | Activo |
| `900001572` | Antología Esencial | $12,000 | $8,400 | $10,800 | Activo |
| `900001575` | La vida real | $15,000 | $10,500 | $13,500 | Activo |
| `900001576` | Antología poética. El mar no tiene dioses | $15,000 | $10,500 | $13,500 | Activo |
| `900001577` | Tiempo pasado. Cultura de la memoria y giro subjetivo. Una discusión | $15,000 | $10,500 | $13,500 | Activo |
| `900001578` | A pesar del oscuro silencio | $15,000 | $10,500 | $13,500 | Activo |
| `900001579` | Safari Accidental | $15,000 | $10,500 | $13,500 | Activo |
| `900001580` | Antología poética | $15,000 | $10,500 | $13,500 | Activo |
| `900001581` | La cosas de la vida | $15,000 | $10,500 | $13,500 | Activo |
| `900001582` | Cuando fui mortal | $15,000 | $10,500 | $13,500 | Activo |
| `900001583` | La forma inicial: Conversaciones en Princeton | $15,000 | $10,500 | $13,500 | Activo |
| `900001602` | Carlos Silva Sánchez, 50 años de ajedrez | $12,000 | $8,400 | $10,800 | Activo |
| `900001604` | Aspectos de la música del Siglo XX | $16,000 | $11,200 | $14,400 | Activo |
| `900001605` | Al ritmo de las maderas. Estrategias innovadoras para el aprendizaje interactivo de la música. | $20,000 | $14,000 | $18,000 | Activo |
| `900001606` | Arquitectura y Estructuras. Tomo I: Conceptos Generales | $18,000 | $12,600 | $16,200 | Activo |
| `900001607` | Introducción a la Economía de la Educación. El fenómeno educativo y su connotación económica. | $14,000 | $9,800 | $12,600 | Activo |
| `900001612` | Decisiones Económico-Financieras en el manejo forestal. Segunda Edición | $14,000 | $9,800 | $12,600 | Activo |
| `900001614` | Sistemas Sanguíneos Eritrocitarios de importancia clínica | $14,000 | $9,800 | $12,600 | Activo |
| `900001616` | Geomática de la Vitivinicultura | $16,000 | $11,200 | $14,400 | Activo |
| `900001617` | Bioquímica Clínica, Hematología, Inmunología, Medicina Transfucional, Microbiología y Parasitología. Casos problema del laboratorio. | $30,000 | $21,000 | $27,000 | Activo |
| `900001618` | Economía para no economistas | $14,000 | $9,800 | $12,600 | Activo |
| `900001640` | De Piedras y Montañas, Geología del Maule. Joseph-Hermann Lademann, Franz Schubert, Manfred F. Buchroithner, Universidad de Talca. | $16,000 | $11,200 | $14,400 | Activo |
| `900001654` | A todo arte, Críticas y conversaciones con Waldemar Sommmer. Cecilia Valdés Urrutia. | $38,000 | $26,600 | $34,200 | Activo |
| `900001672` | NADIE MUERE; CLAUDIO BERTONI | $15,000 | $10,500 | $13,500 | Activo |
| `900001702` | ESTUDIOS DE DERECHO FAMILIAR,  Segundas Jornadas Nacionales De Derecho De Familia. Marcela Acuña San Martín, Jorge Del Picó Rubio (Editores) | $35,000 | $24,500 | $31,500 | Activo |
| `900001712` | NO HAY ARMAZÓN QUE LA SOSTENGA, Entrevistas a Diamela Eltit. Edición Mónica Barrientos.	 | $15,000 | $10,500 | $13,500 | Activo |
| `900001715` | SEUDOARAUCANA Y OTRAS BANDERAS. ELVIRA HERNÁNDEZ. | $15,000 | $10,500 | $13,500 | Activo |
| `900001724` | LOS OBSCENOS PÁJAROS DE LA ESPERANZA - RAÚL ZURITA | $15,000 | $10,500 | $13,500 | Activo |
| `900001726` | INOVACIÓN PARA EL DESARROLLO DE TERRITORIOS INTELIGENTES | $15,000 | $10,500 | $13,500 | Activo |
| `900001744` | MICROBIOLOGÍA FUNDAMENTAL | $30,000 | $21,000 | $27,000 | Activo |
| `900001761` | RECONSTRUCCIÓN DE CIUDADES INTERMEDIAS EN EL SIGLO XXI | $25,000 | $17,500 | $22,500 | Activo |
| `900001795` | Música de pájaros | $15,000 | $10,500 | $13,500 | Activo |
| `900001805` | Miguel Littin | $8,000 | $5,600 | $7,200 | Activo |
| `900001810` | INCIDENTES QUE MARCAN LA VIDA | $12,000 | $8,400 | $10,800 | Activo |
| `900001833` | Física Experimental | $35,000 | $24,500 | $31,500 | Activo |
| `900001870` | Carmen Berenguer Crónicas en transición | $15,000 | $10,500 | $13,500 | Activo |
| `900001875` | Raúl Zurita Otra Antología | $15,000 | $10,500 | $13,500 | Activo |
| `900001880` | El Dibujo  desde el error  | $20,000 | $14,000 | $18,000 | Activo |
| `900001890` | El libro uruguayo de los muertos | $15,000 | $10,500 | $13,500 | Activo |
| `900001891` | CRISTINA PIZARRO 50 AÑOS EN LA ESCULTURA | $40,000 | $28,000 | $36,000 | Activo |
| `900001900` | LOS MURMULLOS DE LA AUSENCIA | $15,000 | $10,500 | $13,500 | Activo |
| `900001901` | Cristina Peri Rossi Relatos elegidos   La noche y su artificio (poemas) | $15,000 | $10,500 | $13,500 | Activo |
| `900001911` | Cuando la fruta es más que sólo fruta | $15,000 | $10,500 | $13,500 | Activo |
| `900001922` | DE LA OBESIDAD AL CORONAVIRUS | $14,000 | $9,800 | $12,600 | Activo |
| `900001981` | SUEÑO CON MENGUANTE | $15,000 | $10,500 | $13,500 | Activo |
| `900001993` | LA GRAN REGIÓN MINERA:CHILE Y PERÚ | $15,000 | $10,500 | $13,500 | Activo |
| `900002066` | JANE AUSTEN Y LA ELEGANCIA DE LA MENTE | $12,000 | $8,400 | $10,800 | Activo |
| `900002080` | CUERPOS DESIGUALES | $15,000 | $10,500 | $13,500 | Activo |
| `900002185` | Lo roto precede a lo entero: 125 infraensayos | $15,000 | $10,500 | $13,500 | Activo |
| `900002250` | Escrito sobre España Pablo Neruda | $15,000 | $10,500 | $13,500 | Activo |
| `900002500` | Pájaros en la boca | $15,000 | $10,500 | $13,500 | Activo |
| `900002542` | Francisca Cerda, 50 años de escultura | $30,000 | $21,000 | $27,000 | Activo |
| `900002557` | Química teórica y aplicada | $18,000 | $12,600 | $16,200 | Activo |
| `900002570` | Tantos frentes | $15,000 | $10,500 | $13,500 | Activo |
| `900002581` | Génesis y evolución de la judicatura colonial chilena.  Historia del primer juzgado de Talca | $15,000 | $10,500 | $13,500 | Activo |

### 3.2. Libros No Aptos para Pruebas (Precio $0 en BD)
Los siguientes libros existen en la base de datos pero tienen precio $0, por lo que no se pueden procesar en transacciones reales de venta:
| Código SAP (Material) | Título de Material en BD | Precio Base | Estado en BD |
| :--- | :--- | :---: | :---: |
| `900001498` | Federico Albert, pionero del desarrollo forestal en Chile | $0 | Inactivo |
| `900001507` | Propagación de bulbosas chilenas ornamentales | $0 | Activo |
| `900001508` | Geomática para la ordenación del territorio | $0 | Activo |
| `900001511` | Arquitectura Climática, una contribución al desarrollo sustentable | $0 | Activo |
| `900001516` | Los ramales ferroviarios del Maule | $0 | Activo |
| `900001517` | El resto de la vida. Cuentos. | $0 | Activo |
| `900001525` | Colección de Arte Universidad de Talca. Segunda Edición | $0 | Activo |
| `900001526` | Carlos Pedraza. Maestro del color y la luz | $0 | Activo |
| `900001534` | Colección de Arte Universidad de Talca | $0 | Activo |
| `900001546` | La Inquietante Extrañez | $0 | Activo |
| `900001549` | Pensando en América | $0 | Activo |
| `900001550` | Ruegos y Nubes en el azul | $0 | Activo |
| `900001568` | Crónicas Talquinas | $0 | Activo |
| `900001574` | Los amantes del Guggenheim | $0 | Activo |
| `900001584` | Maulina. Antología poética | $0 | Activo |
| `900001597` | Sucesiones, series y cálculo en varias variables | $0 | Activo |
| `900001610` | Dieta Mediterránea. Prevención de las Enfermedades Cardiovasculares | $0 | Activo |
| `900001804` | MARCOYORA   Rapa Nui o el paraíso interior de Margot Loyola | $0 | Activo |

### 3.3. Libros No Registrados en la Base de Datos
Los siguientes códigos de libros de la lista original no se encontraron en la base de datos de QA (`pove_producto_tl`):
- `900000944`
- `900000942`
- `900000943`
- `900001655`
- `900002520`
- `900000946`
- `900001661`
- `900002530`
- `900001666`
- `900001669`
- `900001694`
- `900000955`
- `900001921`
- `900000960`
- `900000963`
- `900002541`
- `900001840`
- `900002070`
- `900001872`
- `900000968`
- `900002508`
- `900000978`
- `900001692`
- `900002540`
- `900001871`
- `900001970`
- `900002263`
- `900001725`
- `900000989`
- `900000990`
- `900001722`
- `900001417`
- `900001638`
- `900000996`

---

## 4. Casos de Uso y Escenarios de Prueba

### Caso de Uso 1: Compra por Usuario Interno (Comunidad UTalca)
* **Objetivo**: Validar el cobro del 30% de descuento para un funcionario de la universidad y su correcta integración con SAP.
* **Datos de Prueba**:
  - **RUT Cliente**: `15318220-5` (Funcionario)
  - **Libros a comprar**:
    1. ¡Viva la ciencia! (`900001497`) - Cantidad: 1 (Base: $10,000)
    2. El gusto de criticar (`900001522`) - Cantidad: 1 (Base: $20,000)
  - **Despacho / Envío**: Retiro en Tienda ($0) o Costo de despacho según región.
* **Cálculo del Pago**:
  - Subtotal Catálogo: $10,000 + $20,000 = $30,000
  - Subtotal con Descuento (30% off, factor 0.7): $30,000 * 0.7 = $21,000
  - Envío: $0
  - **Total Webpay (Monto a pagar)**: **$21,000**
* **Comportamiento en SAP**:
  - Se genera una orden de venta en SAP con tipo de documento `ZP08`.
  - El precio unitario de cada libro se prorratea y se envía neto en el JSON de integración (`ORDER_CONDITIONS_IN`).
  - Item 1 (`900001497`): $7,000
  - Item 2 (`900001522`): $14,000
  - Suma SAP: $21,000 (Calza 100% con Webpay).

### Caso de Uso 2: Compra por Usuario Externo (Público General)
* **Objetivo**: Validar el cobro del 10% de descuento por defecto para usuarios externos a la universidad.
* **Datos de Prueba**:
  - **RUT Cliente**: `12345678-9` (Externo)
  - **Libros a comprar**:
    1. ¡Viva la ciencia! (`900001497`) - Cantidad: 1 (Base: $10,000)
    2. El gusto de criticar (`900001522`) - Cantidad: 1 (Base: $20,000)
  - **Despacho / Envío**: Retiro en Tienda ($0)
* **Cálculo del Pago**:
  - Subtotal Catálogo: $30,000
  - Subtotal con Descuento (10% off, factor 0.9): $30,000 * 0.9 = $27,000
  - Envío: $0
  - **Total Webpay (Monto a pagar)**: **$27,000**
* **Comportamiento en SAP**:
  - Se genera una orden de venta en SAP con tipo de documento `ZP08`.
  - Item 1 (`900001497`): $9,000
  - Item 2 (`900001522`): $18,000
  - Suma SAP: $27,000 (Calza 100% con Webpay).

### Caso de Uso 3: Compra por Estudiante Activo (UTalca)
* **Objetivo**: Demostrar el impacto del bug crítico de clasificación en estudiantes.
* **Datos de Prueba**:
  - **RUT Cliente**: `12296508-2` (Estudiante activo, sin contrato como funcionario)
  - **Libros a comprar**:
    1. ¡Viva la ciencia! (`900001497`) - Cantidad: 1 (Base: $10,000)
  - **Comportamiento Esperado (Sin Bug)**:
    - `get_esutalca` evalúa a `True`.
    - Se aplica 30% de descuento. Total a pagar: $7,000.
  - **Comportamiento Actual (Con Bug)**:
    - `get_esutalca` evalúa a `False`.
    - Se aplica solo 10% de descuento. Total a pagar: $9,000.

---

## 5. Algoritmo de Prorrateo de Precios para SAP (Commit 66c29f4)
Para evitar discrepancias de centavos en SAP y garantizar que la suma de los ítems en SAP calce perfectamente con el pago total recibido en Webpay, se aplica un prorrateo ponderado basado en el precio total real pagado:

1. **Suma de Precios Catálogo (S)**: La suma del precio base de catálogo de todos los productos en la compra.
2. **Total Venta Real (V)**: El total pagado por el cliente en Webpay (que ya incluye el factor de descuento del usuario y despacho).
3. **Cálculo de Proporción**: Para cada ítem $i$ excepto el último:
   $$	ext{Valor SAP}_i = 	ext{ROUND}\left( rac{	ext{Precio Catálogo}_i 	imes 	ext{Cantidad}_i}{S} 	imes V, 0 ight)$$
4. **Ajuste del Último Ítem**: Para evitar errores por decimales en el redondeo:
   $$	ext{Valor SAP}_{	ext{último}} = V - \sum_{i=1}^{n-1} 	ext{Valor SAP}_i$$
Esto garantiza que la suma de todos los ítems en SAP sea exactamente igual a $V$.
