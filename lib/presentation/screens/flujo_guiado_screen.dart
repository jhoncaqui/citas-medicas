import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/formato_fecha.dart';
import '../../domain/entities/cupo_disponible.dart';
import '../../domain/entities/intencion_asistente.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/reserva_viewmodel.dart';
import '../widgets/tarjeta_accion.dart';

/// HU-04, HU-05 y HU-06 — Flujo guiado por menus.
///
/// Es el **fallback obligatorio** de la seccion 8: permite completar una
/// reserva de extremo a extremo sin depender del modelo conversacional. Por
/// eso comparte estado con el asistente en lugar de duplicarlo: una
/// conversacion a medias continua aqui sin perder lo ya elegido.
class FlujoGuiadoScreen extends StatefulWidget {
  const FlujoGuiadoScreen({super.key});

  @override
  State<FlujoGuiadoScreen> createState() => _FlujoGuiadoScreenState();
}

class _FlujoGuiadoScreenState extends State<FlujoGuiadoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<ReservaViewModel>();
      // Si se llega desde el asistente, el estado ya viene poblado.
      if (vm.especialidades.isEmpty) vm.iniciar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservaViewModel>();

    return PopScope(
      canPop: vm.paso == PasoReserva.especialidad,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.retroceder();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tituloDe(vm.paso)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (vm.paso.index + 1) / PasoReserva.values.length,
              minHeight: 4,
            ),
          ),
        ),
        body: SafeArea(
          child: vm.cargando
              ? const _Cargando()
              : switch (vm.paso) {
                  PasoReserva.especialidad => const _PasoEspecialidad(),
                  PasoReserva.profesional => const _PasoProfesional(),
                  PasoReserva.fecha => const _PasoFecha(),
                  PasoReserva.horario => const _PasoHorario(),
                  PasoReserva.confirmacion => const _PasoConfirmacion(),
                },
        ),
      ),
    );
  }

  static String _tituloDe(PasoReserva paso) => switch (paso) {
    PasoReserva.especialidad => Cadenas.pasoEspecialidad,
    PasoReserva.profesional => Cadenas.pasoProfesional,
    PasoReserva.fecha => Cadenas.pasoFecha,
    PasoReserva.horario => Cadenas.pasoHorario,
    PasoReserva.confirmacion => Cadenas.pasoConfirmacion,
  };
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => Semantics(
    label: Cadenas.semanticaCargando,
    liveRegion: true,
    child: const Center(child: CircularProgressIndicator()),
  );
}

// ---------------------------------------------------------------------
// Paso 1 — Especialidad
// ---------------------------------------------------------------------

class _PasoEspecialidad extends StatelessWidget {
  const _PasoEspecialidad();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservaViewModel>();

    if (vm.especialidades.isEmpty) {
      return const _Vacio(mensaje: Cadenas.sinEspecialidades);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        for (final especialidad in vm.especialidades) ...<Widget>[
          TarjetaAccion(
            titulo: especialidad.nombre,
            detalle: especialidad.descripcion,
            icono: Icons.medical_services_outlined,
            destacada: vm.especialidad?.id == especialidad.id,
            onPressed: () async {
              await vm.elegirEspecialidad(especialidad);
              await vm.avanzar();
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Paso 2 — Profesional
// ---------------------------------------------------------------------

class _PasoProfesional extends StatelessWidget {
  const _PasoProfesional();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservaViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Elegir profesional es opcional: quien solo quiere la cita cuanto
        // antes no deberia tener que decidir por quien.
        TarjetaAccion(
          titulo: Cadenas.cualquierProfesional,
          detalle: 'Te mostramos todos los horarios de la especialidad.',
          icono: Icons.groups_outlined,
          destacada: vm.profesional == null,
          onPressed: () {
            vm.elegirProfesional(null);
            vm.avanzar();
          },
        ),
        const SizedBox(height: 12),
        for (final profesional in vm.profesionales) ...<Widget>[
          TarjetaAccion(
            titulo: profesional.nombreCompleto,
            detalle: 'Colegiatura ${profesional.colegiatura}',
            icono: Icons.person_outline,
            destacada: vm.profesional?.id == profesional.id,
            onPressed: () {
              vm.elegirProfesional(profesional);
              vm.avanzar();
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Paso 3 — Fecha
// ---------------------------------------------------------------------

class _PasoFecha extends StatelessWidget {
  const _PasoFecha();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservaViewModel>();
    // El reloj sale del ViewModel, no del sistema: es el mismo con el que se
    // evalua RN-04.
    final hoy = vm.ahora;

    // RN-04: se ofrecen solo dias desde manana; el dia de hoy suele tener los
    // cupos ya pasados o demasiado proximos.
    final dias = List<DateTime>.generate(
      14,
      (i) => DateTime(hoy.year, hoy.month, hoy.day).add(Duration(days: i + 1)),
    ).where((d) => d.weekday != DateTime.sunday).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        for (final dia in dias) ...<Widget>[
          TarjetaAccion(
            titulo: FormatoFecha.fechaLarga(dia),
            detalle: FormatoFecha.fechaCorta(dia),
            icono: Icons.calendar_today_outlined,
            destacada: vm.fecha == dia,
            onPressed: () {
              vm.elegirFecha(dia);
              vm.avanzar();
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Paso 4 — Horario (HU-05)
// ---------------------------------------------------------------------

class _PasoHorario extends StatelessWidget {
  const _PasoHorario();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservaViewModel>();

    if (vm.cupos.isEmpty) {
      return _Vacio(
        mensaje: Cadenas.sinCuposDisponibles,
        onAccion: vm.retroceder,
        textoAccion: Cadenas.atras,
      );
    }

    final manana = vm.cuposDelTurno(TurnoDia.manana);
    final tarde = vm.cuposDelTurno(TurnoDia.tarde);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (vm.fecha != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    FormatoFecha.fechaLarga(vm.fecha!),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              if (manana.isNotEmpty)
                _GrupoHorarios(titulo: Cadenas.turnoManana, cupos: manana),
              if (tarde.isNotEmpty)
                _GrupoHorarios(titulo: Cadenas.turnoTarde, cupos: tarde),
            ],
          ),
        ),
        _BarraInferior(
          habilitado: vm.cupoSeleccionado != null,
          texto: Cadenas.siguiente,
          onPressed: vm.avanzar,
        ),
      ],
    );
  }
}

class _GrupoHorarios extends StatelessWidget {
  const _GrupoHorarios({required this.titulo, required this.cupos});

  final String titulo;
  final List<CupoDisponible> cupos;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservaViewModel>();

    // Con «cualquier profesional» conviven varios cupos a la misma hora, uno
    // por profesional. Mostrarlos como chips identicos obligaria al paciente a
    // elegir a ciegas entre dos «02:00 p. m.» indistinguibles, asi que se
    // agrupan por profesional. Con un profesional ya elegido la ambiguedad no
    // existe y el encabezado sobra.
    final agrupar =
        vm.profesional == null && _profesionalesDe(cupos).length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (!agrupar)
          _Chips(cupos: cupos)
        else
          for (final profesionalId in _profesionalesDe(cupos)) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                vm.profesionalDe(profesionalId)?.nombreCompleto ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _Chips(
              cupos: cupos
                  .where((c) => c.profesionalId == profesionalId)
                  .toList(),
            ),
          ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// Identificadores de profesional en el orden en que aparecen.
  static List<String> _profesionalesDe(List<CupoDisponible> cupos) {
    final vistos = <String>[];
    for (final c in cupos) {
      if (!vistos.contains(c.profesionalId)) vistos.add(c.profesionalId);
    }
    return vistos;
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.cupos});

  final List<CupoDisponible> cupos;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservaViewModel>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final cupo in cupos)
          _ChipHorario(
            cupo: cupo,
            seleccionado: vm.cupoSeleccionado?.id == cupo.id,
          ),
      ],
    );
  }
}

class _ChipHorario extends StatelessWidget {
  const _ChipHorario({required this.cupo, required this.seleccionado});

  final CupoDisponible cupo;
  final bool seleccionado;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ReservaViewModel>();
    final hora = FormatoFecha.hora(cupo.fechaHoraInicio);

    return ConstrainedBox(
      // RNF-04: area tactil minima incluso en un chip pequeno.
      constraints: const BoxConstraints(minHeight: 48, minWidth: 96),
      child: ChoiceChip(
        label: Text(hora),
        selected: seleccionado,
        // HU-05: un cupo ocupado se muestra deshabilitado, no desaparece de
        // golpe mientras el paciente mira la lista.
        onSelected: cupo.disponible
            ? (_) {
                final motivo = vm.elegirCupo(cupo);
                if (motivo != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(motivo)));
                }
              }
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Paso 5 — Confirmacion (HU-06)
// ---------------------------------------------------------------------

class _PasoConfirmacion extends StatelessWidget {
  const _PasoConfirmacion();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservaViewModel>();
    final cupo = vm.cupoSeleccionado;
    final esquema = Theme.of(context).colorScheme;

    if (cupo == null) {
      return _Vacio(
        mensaje: Cadenas.sinCuposDisponibles,
        onAccion: vm.retroceder,
        textoAccion: Cadenas.atras,
      );
    }

    final profesional = vm.profesionalDe(cupo.profesionalId);
    final sede = vm.sedeDe(cupo.sedeId);
    final consultorio = vm.consultorioDe(cupo.consultorioId);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      _Dato(
                        etiqueta: Cadenas.comprobanteEspecialidad,
                        valor: vm.especialidad?.nombre ?? '-',
                      ),
                      _Dato(
                        etiqueta: Cadenas.comprobanteProfesional,
                        valor: profesional?.nombreCompleto ?? '-',
                      ),
                      _Dato(
                        etiqueta: Cadenas.comprobanteFecha,
                        valor: FormatoFecha.fechaLarga(cupo.fechaHoraInicio),
                      ),
                      _Dato(
                        etiqueta: Cadenas.comprobanteHora,
                        valor: FormatoFecha.hora(cupo.fechaHoraInicio),
                      ),
                      _Dato(
                        etiqueta: Cadenas.comprobanteSede,
                        valor: sede?.nombre ?? '-',
                      ),
                      _Dato(
                        etiqueta: Cadenas.comprobanteConsultorio,
                        valor: consultorio?.codigo ?? '-',
                      ),
                    ],
                  ),
                ),
              ),
              if (vm.fallo != null) ...<Widget>[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    vm.fallo!.mensaje,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: esquema.error),
                  ),
                ),
              ],
            ],
          ),
        ),
        _BarraInferior(
          habilitado: vm.puedeConfirmar,
          texto: vm.confirmando
              ? Cadenas.reservandoEspera
              : Cadenas.confirmarReserva,
          onPressed: () => _confirmar(context, vm),
        ),
      ],
    );
  }

  Future<void> _confirmar(BuildContext context, ReservaViewModel vm) async {
    final navegador = Navigator.of(context);
    if (await vm.confirmar()) {
      navegador.pushReplacementNamed(Rutas.comprobante);
    }
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              etiqueta,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.habilitado,
    required this.texto,
    required this.onPressed,
  });

  final bool habilitado;
  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: habilitado ? onPressed : null,
        child: Text(texto),
      ),
    ),
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.mensaje, this.onAccion, this.textoAccion});

  final String mensaje;
  final VoidCallback? onAccion;
  final String? textoAccion;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (onAccion != null) ...<Widget>[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAccion,
              child: Text(textoAccion ?? Cadenas.atras),
            ),
          ],
        ],
      ),
    ),
  );
}
