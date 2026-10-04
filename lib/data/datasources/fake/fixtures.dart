// =====================================================================
// DATOS DE DEMOSTRACION — PARA PRESENTACION, NO SON EL BACKEND REAL
// =====================================================================
//
// Las especialidades son categorias medicas reales y las sedes usan
// direcciones reales (indicadas para esta presentacion), para que la demo
// se vea natural. Lo que SIGUE siendo inventado, y no debe tomarse como
// dato real de ninguna persona, es: los profesionales (nombres, apellidos
// y numero de colegiatura), los horarios y los identificadores internos
// ('esp-demo-01', 'sede-demo-01', etc.).
//
// Las coordenadas de las sedes son una aproximacion de la ubicacion de la
// avenida (no una geocodificacion exacta del numero de puerta); afinarlas
// antes de activar `FeatureFlags.usarMapas` con una clave real de Google
// Maps.
//
// Este archivo debe eliminarse, o dejar de usarse, cuando la bandera
// `FeatureFlags.usarBackendReal` pase a `true` de forma permanente.
// =====================================================================

import '../../../domain/entities/consultorio.dart';
import '../../../domain/entities/cupo_disponible.dart';
import '../../../domain/entities/especialidad.dart';
import '../../../domain/entities/profesional.dart';
import '../../../domain/entities/sede.dart';

class Fixtures {
  const Fixtures._();

  // Las especialidades y los profesionales son mutables: el personal de
  // administracion puede darlos de alta, editarlos o eliminarlos (CRUD). Se
  // siembran desde una semilla const y pueden restaurarse con [reiniciar],
  // que es lo que usan los tests para no contaminarse entre si.
  static final List<Especialidad> especialidades = List<Especialidad>.of(
    _especialidadesSemilla,
  );

  static final List<Profesional> profesionales = List<Profesional>.of(
    _profesionalesSemilla,
  );

  /// Restaura el catalogo editable a su estado inicial.
  static void reiniciar() {
    especialidades
      ..clear()
      ..addAll(_especialidadesSemilla);
    profesionales
      ..clear()
      ..addAll(_profesionalesSemilla);
    _secuencia = 0;
  }

  /// Contador para generar identificadores unicos de registros nuevos.
  static int _secuencia = 0;

  static String nuevoIdEspecialidad() =>
      'esp-${DateTime.now().microsecondsSinceEpoch}-${_secuencia++}';

  static String nuevoIdProfesional() =>
      'prof-${DateTime.now().microsecondsSinceEpoch}-${_secuencia++}';

  static const List<Especialidad> _especialidadesSemilla = <Especialidad>[
    Especialidad(
      id: 'esp-demo-01',
      nombre: 'Medicina General',
      descripcion:
          'Consulta y atencion medica general para pacientes de todas las '
          'edades.',
    ),
    Especialidad(
      id: 'esp-demo-02',
      nombre: 'Pediatria',
      descripcion:
          'Atencion medica especializada para bebes, ninos y adolescentes.',
    ),
    Especialidad(
      id: 'esp-demo-03',
      nombre: 'Cardiologia',
      descripcion:
          'Diagnostico y tratamiento de enfermedades del corazon y del '
          'sistema circulatorio.',
    ),
    Especialidad(
      id: 'esp-demo-04',
      nombre: 'Dermatologia',
      descripcion:
          'Diagnostico y tratamiento de enfermedades de la piel. '
          'Temporalmente sin atencion (para probar el filtrado).',
      activa: false,
    ),
  ];

  static const List<Profesional> _profesionalesSemilla = <Profesional>[
    Profesional(
      id: 'prof-demo-01',
      nombres: 'Carlos Alberto',
      apellidos: 'Ramirez Soto',
      especialidadId: 'esp-demo-01',
      colegiatura: 'CMP-000001',
    ),
    Profesional(
      id: 'prof-demo-02',
      nombres: 'Maria Fernanda',
      apellidos: 'Torres Vega',
      especialidadId: 'esp-demo-01',
      colegiatura: 'CMP-000002',
    ),
    Profesional(
      id: 'prof-demo-03',
      nombres: 'Luis Miguel',
      apellidos: 'Huaman Rojas',
      especialidadId: 'esp-demo-02',
      colegiatura: 'CMP-000003',
    ),
    Profesional(
      id: 'prof-demo-04',
      nombres: 'Patricia Elena',
      apellidos: 'Salazar Ponce',
      especialidadId: 'esp-demo-03',
      colegiatura: 'CMP-000004',
    ),
  ];

  // Defensores del Morro y Prolongacion Huaylas son, de hecho, la misma
  // avenida costanera de Chorrillos en tramos distintos: las dos sedes
  // quedan cerca una de la otra, lo cual es realista para dos locales de
  // una misma clinica.
  static const List<Sede> sedes = <Sede>[
    Sede(
      id: 'sede-demo-01',
      nombre: 'Sede Defensores del Morro',
      direccion: 'Av. Defensores del Morro 1221, Chorrillos 15064',
      latitud: -12.181000,
      longitud: -77.008000,
      referencia:
          'Sobre la avenida costanera de Chorrillos, cerca del cruce con '
          'Prolongacion Huaylas.',
    ),
    Sede(
      id: 'sede-demo-02',
      nombre: 'Sede Prolongacion Huaylas',
      direccion: 'Av. Prol. Huaylas 365, Lima',
      latitud: -12.178000,
      longitud: -77.000000,
      referencia:
          'Sobre la prolongacion de la avenida Defensores del Morro, en '
          'Chorrillos.',
    ),
  ];

  static const List<Consultorio> consultorios = <Consultorio>[
    Consultorio(
      id: 'cons-demo-01',
      sedeId: 'sede-demo-01',
      codigo: 'C-101',
      piso: 1,
    ),
    Consultorio(
      id: 'cons-demo-02',
      sedeId: 'sede-demo-01',
      codigo: 'C-204',
      piso: 2,
    ),
    Consultorio(
      id: 'cons-demo-03',
      sedeId: 'sede-demo-02',
      codigo: 'N-301',
      piso: 3,
    ),
  ];

  /// Genera cupos ficticios para los proximos [dias] dias a partir de
  /// [desde], en bloques de 30 minutos de 08:00 a 12:00 y de 14:00 a 18:00.
  ///
  /// Se generan de forma relativa al momento actual para que RN-04 (no se
  /// admiten reservas en el pasado) siempre tenga cupos validos que ofrecer,
  /// sin importar cuando se ejecute la aplicacion.
  static List<CupoDisponible> generarCupos({
    required DateTime desde,
    int dias = 14,
    int duracionMinutos = 30,
  }) {
    final cupos = <CupoDisponible>[];
    final base = DateTime(desde.year, desde.month, desde.day);

    for (var dia = 0; dia < dias; dia++) {
      final fecha = base.add(Duration(days: dia));

      // La clinica ficticia no atiende domingos.
      if (fecha.weekday == DateTime.sunday) continue;

      for (var i = 0; i < profesionales.length; i++) {
        final profesional = profesionales[i];
        final consultorio = consultorios[i % consultorios.length];

        for (final horaInicio in const <int>[8, 9, 10, 11, 14, 15, 16, 17]) {
          for (final minuto in <int>[0, duracionMinutos]) {
            if (minuto >= 60) continue;
            final inicio = DateTime(
              fecha.year,
              fecha.month,
              fecha.day,
              horaInicio,
              minuto,
            );

            // RN-04: no se ofrecen cupos anteriores al momento actual.
            if (!inicio.isAfter(desde)) continue;

            cupos.add(
              CupoDisponible(
                id: 'cupo-${profesional.id}-${inicio.toIso8601String()}',
                profesionalId: profesional.id,
                sedeId: consultorio.sedeId,
                consultorioId: consultorio.id,
                fechaHoraInicio: inicio,
                duracionMinutos: duracionMinutos,
              ),
            );
          }
        }
      }
    }
    return cupos;
  }
}
