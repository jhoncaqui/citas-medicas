# Citas Medicas — aplicativo movil con asistente conversacional

Proyecto final de **SIST1502 Desarrollo de Aplicaciones Moviles** — UPN, ciclo 2026-2.

Aplicacion Android en Flutter para la reserva de citas medicas con asistente
conversacional.

---

## Entorno verificado

| Componente | Version |
|---|---|
| Flutter | 3.47.1 estable |
| Dart | 3.13.1 |
| Android SDK | Platform 36, build-tools 36.0.0 |
| JDK | OpenJDK 25 (el empaquetado con Android Studio) |
| `material_ui` | 1.3.0 (paquete oficial de flutter.dev) |

`flutter doctor` debe reportar **No issues found** antes de compilar.

> **`material_ui`, no `flutter/material.dart`.** Desde Flutter 3.47 las
> bibliotecas Material y Cupertino viven en paquetes propios. El proyecto usa
> `package:material_ui/material_ui.dart` en todo el codigo. Los delegados de
> localizacion tambien salen de ahi (`GlobalMaterialLocalizations.delegates`),
> no de `flutter_localizations`.

---

## Como ejecutar

```bash
flutter pub get
flutter run
```

Con las banderas en sus valores por defecto, la aplicacion **arranca sin
backend, sin Firebase y sin Google Maps**: los datos salen de fixtures
locales.

Para apuntar al backend real:

```bash
flutter run --dart-define=USAR_BACKEND_REAL=true --dart-define=URL_BASE_API=https://tu-host/api/v1
```

Verificacion antes de entregar:

```bash
flutter analyze   # debe decir "No issues found!"
flutter test      # deben pasar todos
```

---

## Arquitectura

MVVM en cuatro capas, con `provider` como gestor de estado.

```
Vista (screens, widgets)
  v
ModeloDeVista (viewmodels, ChangeNotifier)
  v
Repositorio (domain/repositories, contratos + data/repositories, implementacion)
  v
FuenteDeDatos (data/datasources: remote, local, fake)
```

### Regla de dependencias

- `presentation` depende de `domain`.
- `data` implementa `domain`.
- **`domain` no depende de nada externo**: ni de HTTP, ni de sqflite, ni de
  Firebase, ni siquiera de `material_ui`.
- La vista no contiene logica de negocio ni llama a fuentes de datos.

### Estructura

```
lib/
├── main.dart                 # composicion de dependencias
├── app/                      # MaterialApp, rutas, tema
│   └── theme/                # paleta con contrastes WCAG verificados
├── core/
│   ├── config/               # app_config.dart, feature_flags.dart
│   ├── error/                # FalloApp y Resultado<T>
│   ├── network/              # ApiClient, ConnectivityService
│   └── utils/
├── data/
│   ├── models/               # DTO con fromJson/toJson y mapeo a dominio
│   ├── datasources/
│   │   ├── remote/           # cliente REST
│   │   ├── local/            # sqflite y shared_preferences
│   │   └── fake/             # fixtures (datos FICTICIOS)
│   └── repositories/         # implementacion de los contratos
├── domain/
│   ├── entities/             # clases inmutables con copyWith, == y hashCode
│   ├── repositories/         # contratos abstractos
│   └── rules/                # reglas RN-01 a RN-10
├── presentation/
│   ├── viewmodels/
│   ├── screens/
│   └── widgets/
└── l10n/                     # cadenas en es_PE
```

---

## Banderas de entorno

Definidas en `lib/core/config/feature_flags.dart`, todas en `false` por
defecto. Se sobrescriben con `--dart-define`.

| Bandera | En `false` | Requisito para ponerla en `true` |
|---|---|---|
| `USAR_BACKEND_REAL` | Fixtures locales con latencia simulada | Backend Spring Boot desplegado |
| `USAR_FIREBASE` | Autenticacion local de desarrollo; recordatorios por consola | `android/app/google-services.json` |
| `USAR_MAPAS` | La pantalla de ubicacion muestra direccion y referencia en texto | Clave de API de Google Maps |

**Ninguna clave ni `google-services.json` se versiona.** Se inyectan por
`--dart-define` o por `local.properties`, fuera del control de versiones.

---

## Parametros pendientes

`lib/core/config/app_config.dart` contiene tres plazos que **no estan fijados
en duro** y que deben confirmarse con la entrevista al personal de admision:

- `horasMinimasParaAutogestion` — la «N horas» de **RN-06**.
- `horasAntelacionRecordatorio` — la «M horas» de **RN-07**.
- `horasParaMarcarInasistencia` — margen de **RN-08**.

Los valores presentes son marcadores de trabajo, no el dato real.

---

## Configuracion Android

- `minSdk 26` (Android 8.0) — decision documentada de ODS 12 para no excluir
  terminales de gama de entrada. **No subir este valor.**
- `targetSdk 36` (Android 16) — exigido por Google Play desde el 31/08/2026.
- **Edge-to-edge obligatorio:** al apuntar a API 36 el contenido se dibuja
  detras de las barras del sistema y no se puede desactivar. Toda pantalla se
  envuelve en `SafeArea`.
- **Solo HTTPS (RNF-08):** `usesCleartextTraffic="false"` mas
  `network_security_config.xml`. El `ApiClient` vuelve a comprobarlo antes de
  enviar.

---

## Accesibilidad (RNF-04, WCAG 2.1 AA)

- Contraste minimo 4.5:1. Los ratios calculados estan anotados junto a cada
  color en `lib/app/theme/app_colors.dart`.
- Area tactil minima de 48 dp, aplicada desde el tema
  (`AppTheme.areaTactilMinima`) y verificada por test.
- `Semantics` en los controles no textuales.
- Escalado de fuente del sistema soportado hasta 2x sin romper el diseno.

---

## Autenticacion

Con `USAR_FIREBASE` en `false`, las cuentas son **locales de este
dispositivo** (`FakePacienteDataSource`). No hay verificacion de correo ni
recuperacion de contrasena, y el «token» es un identificador local, no un JWT
firmado. Lo que si se respeta, porque son requisitos y no detalles de
implementacion:

- La clave nunca se guarda en claro: SHA-256 con sal distinta por cuenta.
- Token y perfil viven en el almacen cifrado (`flutter_secure_storage`),
  nunca en `shared_preferences` (RNF-08).
- El fallo de inicio de sesion es identico para «documento no registrado» y
  «contrasena incorrecta» (HU-02), para no filtrar que documentos existen.

Las reglas de negocio implementadas viven en `lib/domain/rules/` como
funciones puras, cada una con sus tests:

| Regla | Archivo |
|---|---|
| RN-01 — solo pacientes autenticados operan sobre citas | `rn01_autenticacion.dart` |
| RN-02 — validacion de DNI y carne de extranjeria | `rn02_documento_identidad.dart` |
| RN-03, RN-04, RN-05 — cupo unico, nada en el pasado, sin duplicados | `rn03_rn04_rn05_reserva.dart` |
| RN-06, RN-07, RN-08 — plazo de autogestion, recordatorio, inasistencia | `rn06_rn07_rn08_gestion.dart` |
| RN-09 — guardarrail clinico | `rn09_guardarrail_clinico.dart` |
| RN-10 — consentimiento previo y revocable | `rn10_consentimiento.dart` |

RN-01 se aplica en dos capas: la puerta de entrada no deja llegar a las
pantallas de gestion sin sesion, y cada operacion protegida vuelve a
consultar la regla antes de tocar el repositorio.

---

## Cuentas de demostracion

Con la autenticacion local (`USAR_FIREBASE` en `false`) se siembran ocho
cuentas. La **clave comun** esta en
`lib/data/datasources/fake/cuentas_demo.dart`, junto al resto de los datos.

| Rol | Usuario o documento | Nombre |
|---|---|---|
| Administrador | `jcaqui` | Caqui Calixto, Jhon Daniel |
| Administrador | `emamani` | Mamani Quispe, Elmer Willie |
| Administrador | `ksaavedra` | Saavedra Bautista, Karen Margarita |
| Paciente | `00000001` a `00000005` | Paciente Uno a Cinco Ficticio Ejemplo |

Los pacientes son **ficticios**: los DNI empiezan por `0000000` a proposito,
porque ningun DNI real tiene ese formato y asi no pueden coincidir con el de
una persona de verdad. El usuario admite minusculas.

**Que hace cada rol**

- **Paciente**: reserva, reprograma, cancela y consulta su historial.
- **Administrador**: ve el panel de indicadores (HU-11) con las citas de
  **todos** los pacientes. **No reserva ni gestiona citas propias** (RN-01): una
  reserva hecha por el personal distorsionaria los propios indicadores.

**Como se comportan**

- Se siembran **una sola vez por almacen**. Si una cuenta se elimina desde
  «Privacidad y datos» (HU-12) no reaparece; para recuperarlas, borra los datos
  de la aplicacion o reinstala.
- Nacen con el consentimiento (RN-10) ya otorgado: es un atajo de demostracion,
  porque no pasaron por el registro.
- El rol **no se puede pedir al registrarse**: quien se registra desde la
  aplicacion es siempre paciente, aunque envie otra cosa.

**En compilaciones release estan apagadas por defecto**
(`FeatureFlags.sembrarCuentasDemo`): un AAB no debe salir con credenciales
conocidas incrustadas. Para una demostracion con el AAB, activalas
expresamente:

```bash
flutter build appbundle --release --dart-define=SEMBRAR_CUENTAS_DEMO=true
```

Con Firebase o con el backend real no hay autenticacion local donde sembrar, y
las cuentas desaparecen solas. **La clave de demostracion no debe usarse en
ningun sistema real.**

---

## El asistente conversacional

La aplicacion **no ejecuta el modelo**: envia el texto al backend y recibe
intencion, entidades y confianza. Con `USAR_BACKEND_REAL` en `false`,
`FakeAsistenteDataSource` resuelve las intenciones con expresiones regulares y
devuelve **la misma estructura** que devolvera Rasa.

Tres comportamientos que no son negociables y estan cubiertos por tests:

- **Umbral de confianza** (`AppConfig.umbralConfianza`, 0.70): por debajo, el
  asistente pide reformulacion y **no ejecuta ninguna accion**.
- **Fallback obligatorio**: tras dos intentos fallidos consecutivos se ofrece
  el flujo guiado por menus, que completa la reserva de extremo a extremo sin
  depender del modelo.
- **RN-09**: el guardarrail clinico se evalua **antes** de enviar nada. Si el
  mensaje describe sintomas o pide orientacion clinica, se deriva al canal de
  atencion y el texto **no sale del dispositivo**. La regla se cumple aunque
  el modelo no este entrenado para ello.

La normalizacion de fechas en espanol («manana», «el lunes», «la proxima
semana») ocurre en el cliente, en `core/utils/fechas_naturales.dart`. **La
fecha resuelta siempre se muestra al paciente para que la confirme**: ninguna
interpretacion se da por buena en silencio.

### Idempotencia de la reserva (RNF-07)

Cada intento de reserva lleva una clave de idempotencia que **no cambia entre
reintentos** y solo se libera cuando la cita queda confirmada. Si la red se
cae despues de enviar la peticion pero antes de recibir la respuesta, el
reintento devuelve la cita ya creada en lugar de crear una segunda.

---

## Persistencia local (HU-09)

El historial se guarda en **sqflite** (`data/datasources/local/`). La politica
de datos es:

- **Disponibilidad de cupos**: siempre remota. Un cupo cacheado es un cupo que
  probablemente ya no existe.
- **Historial**: remoto cuando hay conexion —guardando siempre en sqflite— y
  local cuando no la hay. La pantalla indica **de cuando son los datos** y si
  se estan sirviendo sin conexion.

En modo demostracion el «servidor» simulado guarda su estado en esa misma base.
Sin eso, cerrar la aplicacion equivaldria a que el servidor olvidara todas las
citas, y el historial apareceria vacio justo despues de reservar. Con ello,
tambien sobreviven al reinicio el bloqueo de cupo de **RN-03** y la clave de
idempotencia de **RNF-07**.

## Recordatorios (HU-08)

`ServicioRecordatorios` aisla Firebase Cloud Messaging tras una interfaz
(RNF-12). Con `USAR_FIREBASE` en `false`, `RecordatoriosEnConsola` no envia
nada: deja constancia en `logcat` de **cuando** se habria enviado y con que
contenido, que es lo que permite comprobar RN-07 sin un proyecto de Firebase.

El permiso `POST_NOTIFICATIONS` se solicita **al confirmar la primera cita**,
nunca al arrancar (seccion 11).

---

## Ubicacion e indicadores

**HU-10.** Con `USAR_MAPAS` en `false` la pantalla **no instancia el mapa**:
muestra direccion, referencia y consultorios en texto, que basta para llegar.
El boton de indicaciones abre la aplicacion de mapas del dispositivo con el
esquema `geo:`, sin atar el proyecto a un proveedor, y cae al navegador si no
hay ninguna instalada.

No se declara **ningun permiso de ubicacion**: HU-10 muestra donde esta la
sede, no donde esta el paciente.

**HU-11.** El panel calcula citas reservadas, canceladas, inasistencias,
atendidas y la **proporcion de reservas autogestionadas**, con reparto por
canal y tres periodos. Las proporciones devuelven «Sin datos suficientes»
cuando el denominador es cero: mostrar «0 %» sobre cero casos seria enganoso.

> Mientras no exista el backend, el panel solo ve las citas del paciente de la
> sesion, no las de la clinica. **La pantalla lo dice explicitamente** en lugar
> de presentar la muestra como si fuera toda la operacion.

---

## Entrega: claves y firma

Nada de esto esta en el repositorio, y **no debe anadirse**. Los tres archivos
estan en `.gitignore`.

### 1. Clave de Google Maps (HU-10)

Anade a `android/local.properties` (fuera del control de versiones):

```properties
MAPS_API_KEY=tu_clave_aqui
```

El manifiesto la toma de ahi. Despues, ejecuta con la bandera activa:

```bash
flutter run --dart-define=USAR_MAPAS=true
```

Sin la clave, el proyecto compila igual y la pantalla usa el modo texto.

### 2. Logo de la clinica

Sustituye `assets/images/logo.png` por el logo real **conservando el nombre**.
No hay que tocar codigo ni `pubspec.yaml`: la carpeta ya esta declarada.

El archivo que acompana al proyecto es un **marcador** (recuadro discontinuo
con dos diagonales), deliberadamente neutro para que nadie lo confunda con un
logo definitivo.

- Formato: PNG con transparencia.
- Tamano recomendado: 512x512 px o mayor, cuadrado.
- Se muestra a 96 dp en el inicio de sesion y a 64 dp en el registro; el ancho
  se ajusta solo conservando la proporcion.
- Es **decorativo**: se marca como tal para que el lector de pantalla lo
  ignore y no anada ruido antes del formulario.

Si el archivo faltara, la pantalla no se rompe: dibuja el mismo hueco en
codigo.

### 3. Firebase (HU-08, autenticacion y analitica)

Coloca `android/app/google-services.json` del proyecto de Firebase y ejecuta
con `--dart-define=USAR_FIREBASE=true`. Sin ese archivo la aplicacion usa la
autenticacion local y los recordatorios por consola.

### 4. Firma del AAB

`flutter build appbundle --release` **ya funciona** sin configuracion: genera
un AAB firmado con la clave de depuracion, util para probar pero **no
publicable en Google Play**.

Para el AAB de entrega, genera el almacen de claves y su `key.properties`. Son
credenciales del equipo: creense en el equipo, no se versionan y no se
comparten por chat.

```bash
keytool -genkey -v -keystore upn-citas.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upn
```

Luego crea `android/key.properties`:

```properties
storeFile=../upn-citas.jks
storePassword=...
keyAlias=upn
keyPassword=...
```

Con ese archivo presente, `build.gradle.kts` firma el release con esa clave en
lugar de la de depuracion. **Si se pierde el almacen de claves, no se pueden
publicar actualizaciones de la aplicacion**: guardese con cuidado.

---

## Datos de prueba

`lib/data/datasources/fake/fixtures.dart` contiene **datos ficticios**:
especialidades, profesionales, sedes, consultorios y horarios inventados.
No corresponden a ninguna institucion real. Los nombres ("Demo", "Ficticio",
"Ejemplo") lo hacen evidente a simple vista.

---

## Estado por fases

| Fase | Alcance | Estado |
|---|---|---|
| 0 | Andamiaje: estructura, tema, dominio, fixtures, pantalla de inicio | Completada |
| 1 | HU-01, HU-02, HU-12 — cuentas y consentimiento | Completada |
| 2 | HU-03 a HU-06 — reserva de extremo a extremo y asistente | Completada |
| 3 | HU-07 a HU-09 — gestion, recordatorios e historial sin conexion | Completada |
| 4 | HU-10, HU-11 — mapas, indicadores y AAB firmado | Completada |
