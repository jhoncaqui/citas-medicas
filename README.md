# Citas Médicas — Aplicación Web con Asistente Conversacional

Aplicación web React + TypeScript (Vite + Tailwind CSS) para la gestión y reserva de citas médicas con asistente conversacional y flujo guiado paso a paso, reescrita a partir del proyecto original para Google AI Studio.

---

## Características Principales

1. **Autenticación y Sesión (HU-01, HU-02, RN-01, RN-02, RN-10)**
   - Inicio de sesión para pacientes (por DNI o Carné de Extranjería) y personal de administración (por nombre de usuario).
   - Registro de pacientes con validación estricta de documentos de identidad (RN-02).
   - Consentimiento informado previo y explícito para el tratamiento de datos personales (RN-10).
   - Acceso rápido a cuentas demo preconfiguradas tanto para pacientes como para administradores.

2. **Asistente Conversacional (HU-03, RN-09)**
   - Reserva de citas mediante lenguaje natural.
   - Reconocedor heurístico de intenciones y extractor de entidades (especialidad, profesional, fecha, turno, hora).
   - **Guardarraíl clínico estricto (RN-09)**: Detecta síntomas y pedidos de diagnóstico médico, derivando inmediatamente al canal de atención de salud sin emitir recomendaciones clínicas.
   - Confirmación explícita de fechas interpretadas antes de avanzar.
   - Fallback automático al flujo guiado tras 2 intentos fallidos consecutivos.

3. **Flujo Guiado Paso a Paso (HU-04, HU-05, HU-06)**
   - Proceso estructurado en 5 pasos: Especialidad, Profesional, Día, Horario y Confirmación.
   - Consulta de disponibilidad en tiempo real con bloqueo inmediato de cupos (RN-03).
   - Validación contra reservas en fechas/horarios pasados o con menos de 15 min de anticipación (RN-04).
   - Prevención de duplicados para un mismo paciente, día y profesional (RN-05).
   - Idempotencia en reservas para prevenir duplicados ante reintentos de red (RNF-07).
   - Emisión de comprobante digital digital-first sin requerir impresión en papel (ODS 12).

4. **Gestión de Citas e Historial (HU-07, HU-08, HU-09, RN-06, RN-08)**
   - Listado diferenciado de citas próximas (activas) y anteriores (atendidas, canceladas, inasistencias).
   - Cancelación y reprogramación autogestionada hasta 24 horas antes del horario fijado (RN-06).
   - Detección automática de inasistencias tras 2 horas del inicio sin registro de atención (RN-08).
   - Soporte para consulta en modo sin conexión con indicador de última sincronización (HU-09).

5. **Ubicación de Sedes (HU-10)**
   - Directorio de sedes clínicas (Sede Defensores del Morro, Sede Prolongación Huaylas) con consultorios y pisos.
   - Mapa interactivo con coordenadas y enlace directo a Google Maps para navegación.

6. **Panel de Indicadores para Admisión (HU-11)**
   - Exclusivo para usuarios con rol de administrador (RN-01).
   - Métricas en tiempo real: citas reservadas, canceladas, inasistencias, atendidas y tasa de autogestión.
   - Desglose de reservas por canal (conversacional, flujo guiado, telefónico, presencial).

7. **Privacidad y Derechos del Paciente (HU-12, RN-10)**
   - Consulta del estado de vigencia del consentimiento.
   - Revocación directa del consentimiento sin fricciones ni patrones oscuros.
   - Eliminación completa de la cuenta y sus datos locales.

---

## Cuentas de Demostración

| Rol | Documento / Usuario | Contraseña | Nombre |
|---|---|---|---|
| Paciente | `00000001` | `clave1234` | Paciente Uno Ficticio |
| Paciente | `00000002` | `clave1234` | Paciente Dos Ficticio |
| Administrador | `JCAQUI` | `clave1234` | Jhon Daniel Caqui Calixto |
| Administrador | `EMAMANI` | `clave1234` | Elmer Willie Mamani Quispe |
| Administrador | `KSAAVEDRA` | `clave1234` | Karen Margarita Saavedra Bautista |

---

## Stack Tecnológico

- **Runtime**: Node.js 22
- **Framework**: React 19 + TypeScript
- **Bundler / Servidor Dev**: Vite
- **Estilos**: Tailwind CSS v4 (paleta de alta accesibilidad WCAG 2.1 AA)
- **Iconos**: Lucide React
- **Almacenamiento**: Persistencia local cifrada / localStorage con soporte de sembrado
