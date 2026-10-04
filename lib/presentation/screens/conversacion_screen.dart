import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/entities/intencion_asistente.dart';
import '../../domain/entities/mensaje_conversacion.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/conversacion_viewmodel.dart';
import '../viewmodels/reserva_viewmodel.dart';

/// HU-03 — Reserva en lenguaje natural.
class ConversacionScreen extends StatefulWidget {
  const ConversacionScreen({super.key});

  @override
  State<ConversacionScreen> createState() => _ConversacionScreenState();
}

class _ConversacionScreenState extends State<ConversacionScreen> {
  final TextEditingController _controlador = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReservaViewModel>()
        ..reiniciar()
        ..iniciar(canal: CanalReserva.conversacional);
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConversacionViewModel>();

    // Cuando el asistente ya reunio especialidad y fecha, se pasa al flujo
    // guiado en el paso de horarios: es el mismo estado, otra presentacion.
    if (vm.listoParaHorarios) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        vm.horariosAtendidos();
        final reserva = context.read<ReservaViewModel>()
          ..canal = CanalReserva.conversacional
          ..irA(PasoReserva.horario);
        reserva.cargarCupos();
        Navigator.of(context).pushNamed(Rutas.flujoGuiado);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _bajarDelTodo());

    return Scaffold(
      appBar: AppBar(title: const Text(Cadenas.reservarConAsistente)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Semantics(
                label: Cadenas.semanticaConversacion,
                container: true,
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.mensajes.length,
                  itemBuilder: (context, i) =>
                      _Burbuja(mensaje: vm.mensajes[i]),
                ),
              ),
            ),

            if (vm.fechaPorConfirmar != null)
              _ConfirmacionFecha(fecha: vm.fechaPorConfirmar!),

            if (vm.debeOfrecerFlujoGuiado) const _OfrecerFlujoGuiado(),

            _Redaccion(
              controlador: _controlador,
              habilitado: !vm.procesando,
              onEnviar: (texto) {
                _controlador.clear();
                vm.enviar(texto);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _bajarDelTodo() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje});

  final MensajeConversacion mensaje;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final esPaciente = mensaje.esDelPaciente;

    return Align(
      alignment: esPaciente ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: esPaciente
            ? Cadenas.semanticaMensajePaciente
            : Cadenas.semanticaMensajeAsistente,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          decoration: BoxDecoration(
            color: esPaciente
                ? esquema.primaryContainer
                : esquema.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            mensaje.texto,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: esPaciente
                  ? esquema.onPrimaryContainer
                  : esquema.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// La fecha resuelta se muestra siempre para que el paciente la confirme.
class _ConfirmacionFecha extends StatelessWidget {
  const _ConfirmacionFecha({required this.fecha});

  final DateTime fecha;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ConversacionViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FilledButton(
              onPressed: vm.confirmarFecha,
              child: const Text(Cadenas.asistenteSiEsCorrecto),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: vm.rechazarFecha,
              child: const Text(Cadenas.asistenteNoEsCorrecto),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback obligatorio: permite completar la reserva sin el modelo.
class _OfrecerFlujoGuiado extends StatelessWidget {
  const _OfrecerFlujoGuiado();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          context.read<ReservaViewModel>().canal = CanalReserva.flujoGuiado;
          Navigator.of(context).pushNamed(Rutas.flujoGuiado);
        },
        icon: const Icon(Icons.list_alt_outlined),
        label: const Text(Cadenas.asistenteIrAFlujoGuiado),
      ),
    ),
  );
}

class _Redaccion extends StatelessWidget {
  const _Redaccion({
    required this.controlador,
    required this.habilitado,
    required this.onEnviar,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final ValueChanged<String> onEnviar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controlador,
              enabled: habilitado,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: onEnviar,
              decoration: const InputDecoration(
                labelText: Cadenas.asistenteEscribeAqui,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: AppTheme.areaTactilMinima,
            child: IconButton.filled(
              tooltip: Cadenas.asistenteEnviar,
              onPressed: habilitado ? () => onEnviar(controlador.text) : null,
              icon: habilitado
                  ? const Icon(Icons.send)
                  : const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
