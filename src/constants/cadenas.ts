export const Cadenas = {
  // Aplicacion
  nombreApp: 'Citas Médicas',
  descripcionApp: 'Reserva tu cita conversando o paso a paso.',

  // Pantalla de inicio
  saludo: 'Hola',
  tituloInicio: 'Inicio',
  reservarConAsistente: 'Reservar conversando',
  reservarConAsistenteDetalle: 'Escribe lo que necesitas y el asistente te guía.',
  reservarPasoAPaso: 'Reservar paso a paso',
  reservarPasoAPasoDetalle: 'Elige especialidad, fecha y hora desde un menú.',
  misCitas: 'Mis citas',
  misCitasDetalle: 'Consulta, reprograma o cancela.',
  ubicacionSedes: 'Ubicación de sedes',
  ubicacionSedesDetalle: 'Cómo llegar a tu consultorio.',

  // Catalogo
  especialidadesDisponibles: 'Especialidades disponibles',
  sinEspecialidades: 'No hay especialidades disponibles en este momento.',
  cargando: 'Cargando...',
  reintentar: 'Reintentar',

  // Accesibilidad
  semanticaListaEspecialidades: 'Lista de especialidades disponibles',
  semanticaCambiarTema: 'Cambiar entre tema claro y oscuro',
  semanticaCargando: 'Cargando información',
  semanticaMostrarClave: 'Mostrar la contraseña',
  semanticaOcultarClave: 'Ocultar la contraseña',

  // Tema
  temaSistema: 'Según el sistema',
  temaClaro: 'Claro',
  temaOscuro: 'Oscuro',

  // Estado de desarrollo
  avisoDatosFicticios: 'Modo demostración: los datos mostrados son ficticios.',

  // RN-09 — guardarrail clinico
  derivacionCanalAtencion:
    'No puedo orientarte sobre síntomas ni recomendarte una especialidad. ' +
    'Comunícate con el canal de atención de la clínica para que te oriente ' +
    'el personal de salud.',

  // Errores genericos
  errorGenerico: 'Ocurrió un problema. Inténtalo de nuevo.',

  // HU-01 — Registro
  tituloRegistro: 'Crear cuenta',
  subtituloRegistro: 'Necesitamos estos datos para reservar tus citas.',
  tipoDocumento: 'Tipo de documento',
  numeroDocumento: 'Número de documento',
  documentoOUsuario: 'Documento o usuario',
  ingresaDocumentoOUsuario: 'Ingresa tu documento o usuario.',
  nombres: 'Nombres',
  apellidos: 'Apellidos',
  correo: 'Correo electrónico',
  telefono: 'Celular',
  clave: 'Contraseña',
  confirmarClave: 'Repite la contraseña',
  crearCuenta: 'Crear cuenta',
  yaTengoCuenta: 'Ya tengo una cuenta',
  registroCorrecto: 'Tu cuenta se creó correctamente.',

  // HU-02 — Inicio de sesion
  tituloInicioSesion: 'Iniciar sesión',
  subtituloInicioSesion: 'Ingresa con tu documento de identidad.',
  entrar: 'Entrar',
  noTengoCuenta: 'No tengo cuenta, quiero registrarme',
  cerrarSesion: 'Cerrar sesión',

  // RN-10 / HU-12 — Consentimiento y privacidad
  tituloPrivacidad: 'Privacidad y datos',
  consentimientoEtiqueta: 'Autorizo el tratamiento de mis datos personales',
  consentimientoDetalle:
    'Usaremos tus datos únicamente para gestionar tus citas y enviarte ' +
    'recordatorios. No los compartimos con terceros con fines comerciales. ' +
    'Puedes revocar esta autorización en cualquier momento desde ' +
    '"Privacidad y datos".',
  consentimientoVigente: 'Autorización vigente desde el',
  consentimientoRevocado: 'No has autorizado el tratamiento de tus datos.',
  otorgarConsentimiento: 'Autorizar tratamiento de datos',
  revocarConsentimiento: 'Revocar autorización',
  revocarConsentimientoAviso:
    'Al revocar dejarás de poder reservar citas desde la aplicación. Tus ' +
    'citas ya confirmadas se mantienen.',
  eliminarMisDatos: 'Eliminar mi cuenta y mis datos',
  eliminarMisDatosAviso:
    'Se eliminarán tu cuenta, tu perfil y las preferencias guardadas en ' +
    'este dispositivo. Esta acción no se puede deshacer.',
  confirmar: 'Confirmar',
  cancelar: 'Cancelar',
  datosEliminados: 'Tu cuenta y tus datos se eliminaron.',
  consentimientoRevocadoAviso: 'Revocaste la autorización.',
  consentimientoOtorgadoAviso: 'Autorización registrada.',

  // HU-03 — Asistente conversacional
  asistenteSaludo:
    'Hola. Dime qué necesitas: por ejemplo, "quiero una cita de Medicina General para mañana por la tarde".',
  asistenteEscribeAqui: 'Escribe tu mensaje',
  asistenteEnviar: 'Enviar mensaje',
  asistenteNoEntendi: 'No te entendí bien. ¿Puedes decirlo de otra manera?',
  asistenteConfianzaBaja:
    'Creo entender lo que necesitas, pero no estoy seguro. ¿Puedes decirlo de otra manera?',
  asistenteSoloReservas:
    'Por ahora puedo ayudarte a reservar una cita. Para consultar, reprogramar o cancelar, usa "Mis citas".',
  asistenteOfrecerFlujoGuiado:
    'Parece que no nos estamos entendiendo. Puedo llevarte paso a paso, eligiendo de un menú.',
  asistenteIrAFlujoGuiado: 'Reservar paso a paso',
  asistenteFaltaEspecialidad: '¿Para qué especialidad necesitas la cita?',
  asistenteFaltaFecha: '¿Para qué día la necesitas?',
  asistenteConfirmaFecha: 'Entendí esta fecha',
  asistenteSiEsCorrecto: 'Sí, es correcto',
  asistenteNoEsCorrecto: 'No, cambiar',

  // HU-04 / HU-05 — Flujo guiado y disponibilidad
  pasoEspecialidad: 'Elige la especialidad',
  pasoProfesional: 'Elige el profesional',
  pasoFecha: 'Elige el día',
  pasoHorario: 'Elige el horario',
  pasoConfirmacion: 'Confirma tu cita',
  cualquierProfesional: 'Cualquier profesional disponible',
  sinCuposDisponibles: 'No hay horarios disponibles para ese día. Prueba con otra fecha.',
  cargandoCupos: 'Buscando horarios disponibles...',
  turnoManana: 'Mañana',
  turnoTarde: 'Tarde',
  siguiente: 'Siguiente',
  atras: 'Atrás',
  cambiar: 'Cambiar',

  // HU-06 — Confirmacion y comprobante
  confirmarReserva: 'Confirmar cita',
  tituloComprobante: 'Comprobante de tu cita',
  comprobanteEspecialidad: 'Especialidad',
  comprobanteProfesional: 'Profesional',
  comprobanteFecha: 'Fecha',
  comprobanteHora: 'Hora',
  comprobanteSede: 'Sede',
  comprobanteConsultorio: 'Consultorio',
  comprobanteCodigo: 'Código de cita',
  comprobanteEstado: 'Estado',
  comprobanteSinImpresion:
    'Guarda este comprobante en tu teléfono. No necesitas imprimirlo.',
  volverAlInicio: 'Volver al inicio',
  reservaConfirmada: 'Tu cita quedó confirmada.',
  reservandoEspera: 'Confirmando tu cita...',

  // HU-07 y HU-09 — Mis citas
  proximasCitas: 'Próximas citas',
  citasAnteriores: 'Citas anteriores',
  sinCitas: 'Todavía no tienes citas reservadas.',
  sinCitasProximas: 'No tienes citas próximas.',
  reservarAhora: 'Reservar una cita',
  reprogramar: 'Reprogramar',
  cancelarCita: 'Cancelar cita',
  cancelarCitaAviso:
    'Se liberará tu horario para que otra persona pueda tomarlo. Esta acción no se puede deshacer.',
  citaCancelada: 'Tu cita quedó cancelada.',
  citaReprogramada: 'Tu cita quedó reprogramada.',
  sinConexionAviso: 'Sin conexión',
  ultimaSincronizacion: 'Actualizado',
  nuncaSincronizado: 'Aún no se ha sincronizado',
  actualizar: 'Actualizar',
  recordatorioProgramado: 'Te recordaremos tu cita con antelación.',

  // HU-10 — Ubicacion de sedes
  comoLlegar: 'Cómo llegar',
  direccion: 'Dirección',
  referencia: 'Referencia',
  abrirEnMapas: 'Abrir en la aplicación de mapas',
  sinSedes: 'No hay sedes disponibles en este momento.',
  mapaNoDisponible:
    'El mapa no está disponible en esta versión. Abajo tienes la dirección y la referencia para llegar.',
  semanticaMapa: 'Mapa con la ubicación de la sede',

  // HU-11 — Panel de indicadores
  tituloIndicadores: 'Indicadores',
  indicadorReservadas: 'Citas reservadas',
  indicadorCanceladas: 'Canceladas',
  indicadorInasistencias: 'Inasistencias',
  indicadorAtendidas: 'Atendidas',
  indicadorAutogestion: 'Reservas autogestionadas',
  indicadorTasaInasistencia: 'Tasa de inasistencia',
  indicadorPorCanal: 'Reservas por canal',
  indicadorPeriodo: 'Periodo',
  indicadorSinDatos: 'Todavía no hay citas en este periodo.',
  indicadorAvisoAlcance:
    'Estas cifras se calculan sobre las citas registradas en este ' +
    'dispositivo (modo demostración), no sobre la operación real de la ' +
    'clínica.',
  indicadorSinDenominador: 'Sin datos suficientes',
};
