import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/formato_fecha.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/reserva_viewmodel.dart';

/// HU-06 — Comprobante digital de la cita.
///
/// ODS 12 (decision 2): el comprobante vive en la pantalla y **no ofrece
/// impresion**. No hay boton de imprimir ni de exportar a PDF: la cita se
/// consulta en la aplicacion, que ya la tiene.
class ComprobanteScreen extends StatelessWidget {
  const ComprobanteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservaViewModel>();
    final cita = vm.citaConfirmada;
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    if (cita == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(Cadenas.tituloComprobante)),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(Rutas.inicio, (_) => false),
                child: const Text(Cadenas.volverAlInicio),
              ),
            ),
          ),
        ),
      );
    }

    final profesional = vm.profesionalDe(cita.profesionalId);
    final especialidad = vm.especialidadDe(cita.especialidadId);
    final sede = vm.sedeDe(cita.sedeId);
    final consultorio = vm.consultorioDe(cita.consultorioId);
    final inicio = cita.fechaHoraInicio;

    return Scaffold(
      appBar: AppBar(
        title: const Text(Cadenas.tituloComprobante),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Semantics(
          label: Cadenas.semanticaComprobante,
          container: true,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.check_circle_outline, color: esquema.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Cadenas.reservaConfirmada,
                      style: textos.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      _Fila(
                        etiqueta: Cadenas.comprobanteEspecialidad,
                        valor: especialidad?.nombre ?? '-',
                      ),
                      _Fila(
                        etiqueta: Cadenas.comprobanteProfesional,
                        valor: profesional?.nombreCompleto ?? '-',
                      ),
                      _Fila(
                        etiqueta: Cadenas.comprobanteFecha,
                        valor: inicio == null
                            ? '-'
                            : FormatoFecha.fechaLarga(inicio),
                      ),
                      _Fila(
                        etiqueta: Cadenas.comprobanteHora,
                        valor: inicio == null ? '-' : FormatoFecha.hora(inicio),
                      ),
                      _Fila(
                        etiqueta: Cadenas.comprobanteSede,
                        valor: sede?.nombre ?? '-',
                      ),
                      _Fila(
                        etiqueta: Cadenas.comprobanteConsultorio,
                        valor: consultorio == null
                            ? '-'
                            : '${consultorio.codigo} (piso ${consultorio.piso})',
                      ),
                      const Divider(height: 32),
                      _Fila(
                        etiqueta: Cadenas.comprobanteEstado,
                        valor: cita.estado.etiqueta,
                      ),
                      _Fila(
                        etiqueta: Cadenas.comprobanteCodigo,
                        valor: cita.id,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                Cadenas.comprobanteSinImpresion,
                style: textos.bodySmall?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  vm.reiniciar();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(Rutas.inicio, (_) => false);
                },
                child: const Text(Cadenas.volverAlInicio),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

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
