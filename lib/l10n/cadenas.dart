/// Cadenas de la interfaz, en espanol de Peru (es_PE).
///
/// Estan centralizadas aqui para que ninguna pantalla lleve texto embebido.
/// Cuando el proyecto incorpore un segundo idioma, este archivo se sustituye
/// por los ARB de `gen-l10n` sin tocar las pantallas: la firma de acceso
/// (`Cadenas.x`) no cambia.
class Cadenas {
  const Cadenas._();

  // Aplicacion
  static const String nombreApp = 'Citas Medicas';
  static const String descripcionApp =
      'Reserva tu cita conversando o paso a paso.';

  // Pantalla de inicio
  static const String saludo = 'Hola';
  static const String tituloInicio = 'Inicio';
  static const String reservarConAsistente = 'Reservar conversando';
  static const String reservarConAsistenteDetalle =
      'Escribe lo que necesitas y el asistente te guia.';
  static const String reservarPasoAPaso = 'Reservar paso a paso';
  static const String reservarPasoAPasoDetalle =
      'Elige especialidad, fecha y hora desde un menu.';
  static const String misCitas = 'Mis citas';
  static const String misCitasDetalle = 'Consulta, reprograma o cancela.';
  static const String ubicacionSedes = 'Ubicacion de sedes';
  static const String ubicacionSedesDetalle = 'Como llegar a tu consultorio.';

  // Catalogo
  static const String especialidadesDisponibles = 'Especialidades disponibles';
  static const String sinEspecialidades =
      'No hay especialidades disponibles en este momento.';
  static const String cargando = 'Cargando...';
  static const String reintentar = 'Reintentar';

  // Accesibilidad (etiquetas Semantics)
  static const String semanticaListaEspecialidades =
      'Lista de especialidades disponibles';
  static const String semanticaCambiarTema =
      'Cambiar entre tema claro y oscuro';
  static const String semanticaCargando = 'Cargando informacion';

  // Tema
  static const String temaSistema = 'Segun el sistema';
  static const String temaClaro = 'Claro';
  static const String temaOscuro = 'Oscuro';

  // Estado de desarrollo
  static const String avisoDatosFicticios =
      'Modo demostracion: los datos mostrados son ficticios.';

  // RN-09 — guardarrail clinico
  static const String derivacionCanalAtencion =
      'No puedo orientarte sobre sintomas ni recomendarte una especialidad. '
      'Comunicate con el canal de atencion de la clinica para que te oriente '
      'el personal de salud.';

  // Errores genericos
  static const String errorGenerico =
      'Ocurrio un problema. Intentalo de nuevo.';

  // -------------------------------------------------------------------
  // HU-01 — Registro
  // -------------------------------------------------------------------
  static const String tituloRegistro = 'Crear cuenta';
  static const String subtituloRegistro =
      'Necesitamos estos datos para reservar tus citas.';
  static const String tipoDocumento = 'Tipo de documento';
  static const String numeroDocumento = 'Numero de documento';

  /// En el inicio de sesion el campo admite tambien el nombre de usuario de
  /// las cuentas de administracion.
  static const String documentoOUsuario = 'Documento o usuario';
  static const String ingresaDocumentoOUsuario =
      'Ingresa tu documento o usuario.';
  static const String nombres = 'Nombres';
  static const String apellidos = 'Apellidos';
  static const String correo = 'Correo electronico';
  static const String telefono = 'Celular';
  static const String clave = 'Contrasena';
  static const String confirmarClave = 'Repite la contrasena';
  static const String crearCuenta = 'Crear cuenta';
  static const String yaTengoCuenta = 'Ya tengo una cuenta';
  static const String registroCorrecto = 'Tu cuenta se creo correctamente.';

  // -------------------------------------------------------------------
  // HU-02 — Inicio de sesion
  // -------------------------------------------------------------------
  static const String tituloInicioSesion = 'Iniciar sesion';
  static const String subtituloInicioSesion =
      'Ingresa con tu documento de identidad.';
  static const String entrar = 'Entrar';
  static const String noTengoCuenta = 'No tengo cuenta, quiero registrarme';
  static const String cerrarSesion = 'Cerrar sesion';

  // -------------------------------------------------------------------
  // RN-10 / HU-12 — Consentimiento y privacidad
  // -------------------------------------------------------------------
  static const String tituloPrivacidad = 'Privacidad y datos';

  static const String consentimientoEtiqueta =
      'Autorizo el tratamiento de mis datos personales';

  /// Texto informativo del consentimiento: finalidad, alcance y derecho de
  /// revocacion, que es lo que exige un consentimiento informado.
  static const String consentimientoDetalle =
      'Usaremos tus datos unicamente para gestionar tus citas y enviarte '
      'recordatorios. No los compartimos con terceros con fines comerciales. '
      'Puedes revocar esta autorizacion en cualquier momento desde '
      '"Privacidad y datos".';

  static const String consentimientoVigente = 'Autorizacion vigente desde el';
  static const String consentimientoRevocado =
      'No has autorizado el tratamiento de tus datos.';
  static const String otorgarConsentimiento = 'Autorizar tratamiento de datos';
  static const String revocarConsentimiento = 'Revocar autorizacion';
  static const String revocarConsentimientoAviso =
      'Al revocar dejaras de poder reservar citas desde la aplicacion. Tus '
      'citas ya confirmadas se mantienen.';
  static const String eliminarMisDatos = 'Eliminar mi cuenta y mis datos';
  static const String eliminarMisDatosAviso =
      'Se eliminaran tu cuenta, tu perfil y las preferencias guardadas en '
      'este dispositivo. Esta accion no se puede deshacer.';
  static const String confirmar = 'Confirmar';
  static const String cancelar = 'Cancelar';
  static const String datosEliminados = 'Tu cuenta y tus datos se eliminaron.';
  static const String consentimientoRevocadoAviso =
      'Revocaste la autorizacion.';
  static const String consentimientoOtorgadoAviso = 'Autorizacion registrada.';

  // Accesibilidad de las pantallas de cuenta
  static const String semanticaMostrarClave = 'Mostrar la contrasena';
  static const String semanticaOcultarClave = 'Ocultar la contrasena';
  static const String semanticaFormularioRegistro = 'Formulario de registro';
  static const String semanticaIrAPrivacidad = 'Abrir privacidad y datos';

  // -------------------------------------------------------------------
  // HU-03 — Asistente conversacional
  // -------------------------------------------------------------------
  static const String asistenteSaludo =
      'Hola. Dime que necesitas: por ejemplo, "quiero una cita de Medicina '
      'General para manana por la tarde". Tambien puedes escribir solo "quiero '
      'una cita" y te voy preguntando lo demas.';
  static const String asistenteEscribeAqui = 'Escribe tu mensaje';
  static const String asistenteEnviar = 'Enviar mensaje';

  // Dictado por voz (voz a texto).
  static const String dictadoTooltip = 'Dictar por voz';
  static const String dictadoDetener = 'Detener el dictado';
  static const String dictadoNoDisponible =
      'El dictado por voz no esta disponible en este dispositivo. Puedes '
      'escribir tu mensaje.';
  static const String dictadoError =
      'No se pudo usar el dictado. Intentalo de nuevo o escribe el mensaje.';
  static const String semanticaDictar = 'Dictar el mensaje por voz';

  static const String asistenteNoEntendi =
      'No te entendi bien. ¿Puedes decirlo de otra manera?';

  static const String asistenteConfianzaBaja =
      'Creo entender lo que necesitas, pero no estoy seguro. ¿Puedes '
      'decirlo de otra manera?';

  static const String asistenteSoloReservas =
      'Por ahora puedo ayudarte a reservar una cita. Para consultar, '
      'reprogramar o cancelar, usa "Mis citas".';

  static const String asistenteOfrecerFlujoGuiado =
      'Parece que no nos estamos entendiendo. Puedo llevarte paso a paso, '
      'eligiendo de un menu.';
  static const String asistenteIrAFlujoGuiado = 'Reservar paso a paso';

  static const String asistenteFaltaEspecialidad =
      '¿Para que especialidad necesitas la cita?';
  static const String asistenteFaltaFecha = '¿Para que dia la necesitas?';

  /// Re-pregunta cuando el paciente responde pero no se reconoce el dato.
  static const String asistenteNoReconociEspecialidad =
      'No reconoci esa especialidad. Escribela por su nombre, por ejemplo '
      '"Medicina General", "Pediatria" o "Cardiologia".';
  static const String asistenteNoReconociFecha =
      'No reconoci la fecha. Dime un dia, por ejemplo "manana", "el lunes" '
      'o "15 de octubre".';

  /// Se muestra siempre la fecha resuelta para que el paciente la confirme:
  /// ninguna interpretacion se da por buena en silencio.
  static const String asistenteConfirmaFecha = 'Entendi esta fecha';
  static const String asistenteSiEsCorrecto = 'Si, es correcto';
  static const String asistenteNoEsCorrecto = 'No, cambiar';

  // -------------------------------------------------------------------
  // HU-04 / HU-05 — Flujo guiado y disponibilidad
  // -------------------------------------------------------------------
  static const String pasoEspecialidad = 'Elige la especialidad';
  static const String pasoProfesional = 'Elige el profesional';
  static const String pasoFecha = 'Elige el dia';
  static const String pasoHorario = 'Elige el horario';
  static const String pasoConfirmacion = 'Confirma tu cita';

  static const String cualquierProfesional = 'Cualquier profesional disponible';
  static const String sinCuposDisponibles =
      'No hay horarios disponibles para ese dia. Prueba con otra fecha.';
  static const String cargandoCupos = 'Buscando horarios disponibles...';
  static const String turnoManana = 'Manana';
  static const String turnoTarde = 'Tarde';
  static const String siguiente = 'Siguiente';
  static const String atras = 'Atras';
  static const String cambiar = 'Cambiar';

  // -------------------------------------------------------------------
  // HU-06 — Confirmacion y comprobante
  // -------------------------------------------------------------------
  static const String confirmarReserva = 'Confirmar cita';
  static const String tituloComprobante = 'Comprobante de tu cita';
  static const String comprobanteEspecialidad = 'Especialidad';
  static const String comprobanteProfesional = 'Profesional';
  static const String comprobanteFecha = 'Fecha';
  static const String comprobanteHora = 'Hora';
  static const String comprobanteSede = 'Sede';
  static const String comprobanteConsultorio = 'Consultorio';
  static const String comprobanteCodigo = 'Codigo de cita';
  static const String comprobanteEstado = 'Estado';

  /// ODS 12 (decision 2): el comprobante es digital y no se imprime.
  static const String comprobanteSinImpresion =
      'Guarda este comprobante en tu telefono. No necesitas imprimirlo.';
  static const String volverAlInicio = 'Volver al inicio';

  static const String reservaConfirmada = 'Tu cita quedo confirmada.';
  static const String reservandoEspera = 'Confirmando tu cita...';

  // -------------------------------------------------------------------
  // HU-07 y HU-09 — Mis citas
  // -------------------------------------------------------------------
  static const String proximasCitas = 'Proximas citas';
  static const String citasAnteriores = 'Citas anteriores';
  static const String sinCitas = 'Todavia no tienes citas reservadas.';
  static const String sinCitasProximas = 'No tienes citas proximas.';
  static const String reservarAhora = 'Reservar una cita';

  static const String reprogramar = 'Reprogramar';
  static const String cancelarCita = 'Cancelar cita';
  static const String cancelarCitaAviso =
      'Se liberara tu horario para que otra persona pueda tomarlo. Esta '
      'accion no se puede deshacer.';
  static const String citaCancelada = 'Tu cita quedo cancelada.';
  static const String citaReprogramada = 'Tu cita quedo reprogramada.';

  /// HU-09: el historial sin conexion debe decir de cuando son los datos.
  static const String sinConexionAviso = 'Sin conexion';
  static const String ultimaSincronizacion = 'Actualizado';
  static const String nuncaSincronizado = 'Aun no se ha sincronizado';
  static const String actualizar = 'Actualizar';

  // HU-08 — recordatorios
  static const String recordatorioProgramado =
      'Te recordaremos tu cita con antelacion.';

  // Accesibilidad de la reserva
  static const String semanticaConversacion = 'Conversacion con el asistente';
  static const String semanticaMensajePaciente = 'Tu mensaje';
  static const String semanticaMensajeAsistente = 'Respuesta del asistente';
  static const String semanticaComprobante = 'Comprobante de la cita';
  static const String semanticaListaCitas = 'Lista de tus citas';

  // -------------------------------------------------------------------
  // HU-10 — Ubicacion de sedes
  // -------------------------------------------------------------------
  static const String comoLlegar = 'Como llegar';
  static const String direccion = 'Direccion';
  static const String referencia = 'Referencia';
  static const String abrirEnMapas = 'Abrir en la aplicacion de mapas';
  static const String sinSedes = 'No hay sedes disponibles en este momento.';
  static const String mapaNoDisponible =
      'El mapa no esta disponible en esta version. Abajo tienes la direccion '
      'y la referencia para llegar.';
  static const String semanticaMapa = 'Mapa con la ubicacion de la sede';

  // -------------------------------------------------------------------
  // HU-11 — Panel de indicadores
  // -------------------------------------------------------------------
  static const String tituloIndicadores = 'Indicadores';
  static const String indicadorReservadas = 'Citas reservadas';
  static const String indicadorCanceladas = 'Canceladas';
  static const String indicadorInasistencias = 'Inasistencias';
  static const String indicadorAtendidas = 'Atendidas';
  static const String indicadorAutogestion = 'Reservas autogestionadas';
  static const String indicadorTasaInasistencia = 'Tasa de inasistencia';
  static const String indicadorPorCanal = 'Reservas por canal';
  static const String indicadorPeriodo = 'Periodo';
  static const String indicadorSinDatos =
      'Todavia no hay citas en este periodo.';

  /// Sin backend, el panel solo ve las citas del paciente de la sesion.
  /// Decirlo evita presentar la muestra como si fuera toda la clinica.
  static const String indicadorAvisoAlcance =
      'Estas cifras se calculan sobre las citas registradas en este '
      'dispositivo (modo demostracion), no sobre la operacion real de la '
      'clinica. Al conectar el backend pasaran a reflejarla.';
  static const String indicadorSinDenominador = 'Sin datos suficientes';

  // -------------------------------------------------------------------
  // Administracion del catalogo (solo cuentas de administracion)
  // -------------------------------------------------------------------
  static const String tituloAdministracion = 'Gestion del catalogo';
  static const String administracionDetalle =
      'Da de alta, edita o elimina especialidades y profesionales.';

  static const String adminPestanaEspecialidades = 'Especialidades';
  static const String adminPestanaProfesionales = 'Profesionales';

  static const String adminNuevaEspecialidad = 'Nueva especialidad';
  static const String adminEditarEspecialidad = 'Editar especialidad';
  static const String adminNuevoProfesional = 'Nuevo profesional';
  static const String adminEditarProfesional = 'Editar profesional';

  static const String adminSinEspecialidades =
      'Todavia no hay especialidades. Agrega la primera con el boton +.';
  static const String adminSinProfesionales =
      'Todavia no hay profesionales. Agrega el primero con el boton +.';
  static const String adminNecesitaEspecialidad =
      'Primero crea al menos una especialidad para poder asignar '
      'profesionales.';

  // Campos de formulario.
  static const String adminCampoNombre = 'Nombre';
  static const String adminCampoDescripcion = 'Descripcion';
  static const String adminCampoActiva = 'Disponible para reservas';
  static const String adminCampoNombres = 'Nombres';
  static const String adminCampoApellidos = 'Apellidos';
  static const String adminCampoEspecialidad = 'Especialidad';
  static const String adminCampoColegiatura = 'Numero de colegiatura';

  static const String adminInactiva = 'No disponible';

  // Acciones.
  static const String adminGuardar = 'Guardar';
  static const String adminCancelar = 'Cancelar';
  static const String adminEliminar = 'Eliminar';
  static const String adminEditar = 'Editar';

  // Confirmacion de borrado.
  static const String adminConfirmarEliminarTitulo = 'Confirmar eliminacion';
  static String adminConfirmarEliminarEspecialidad(String nombre) =>
      '¿Eliminar la especialidad "$nombre"? Esta accion no se puede deshacer.';
  static String adminConfirmarEliminarProfesional(String nombre) =>
      '¿Eliminar al profesional "$nombre"? Esta accion no se puede deshacer.';

  // Avisos de resultado.
  static const String adminGuardado = 'Cambios guardados.';
  static const String adminEliminado = 'Registro eliminado.';

  // Validacion de formularios.
  static const String adminErrorNombreVacio = 'Escribe un nombre.';
  static const String adminErrorNombresVacio = 'Escribe los nombres.';
  static const String adminErrorApellidosVacio = 'Escribe los apellidos.';
  static const String adminErrorColegiaturaVacia =
      'Escribe el numero de colegiatura.';
  static const String adminErrorEspecialidadVacia = 'Elige una especialidad.';
}
