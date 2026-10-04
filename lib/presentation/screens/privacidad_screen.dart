import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/formato_fecha.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/sesion_viewmodel.dart';

/// HU-12 — Revocacion de consentimiento y solicitud de eliminacion de datos.
///
/// Seccion 11, sin patrones oscuros: revocar cuesta exactamente lo mismo que
/// otorgar (un toque y una confirmacion), no se pide motivo, no se intenta
/// retener al paciente y no se vuelve a solicitar la autorizacion despues.
class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionViewModel>();
    final paciente = sesion.paciente;
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(Cadenas.tituloPrivacidad)),
      body: SafeArea(
        child: paciente == null
            ? const _SinSesion()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: <Widget>[
                  // ---------------- Estado del consentimiento ----------------
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                paciente.consentimientoOtorgado
                                    ? Icons.verified_user_outlined
                                    : Icons.gpp_maybe_outlined,
                                color: esquema.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  paciente.consentimientoOtorgado &&
                                          paciente.fechaConsentimiento != null
                                      ? '${Cadenas.consentimientoVigente} '
                                            '${FormatoFecha.fechaCorta(paciente.fechaConsentimiento!)}'
                                      : Cadenas.consentimientoRevocado,
                                  style: textos.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Cadenas.consentimientoDetalle,
                            style: textos.bodySmall?.copyWith(
                              color: esquema.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------------- Otorgar / revocar ----------------
                  if (paciente.consentimientoOtorgado)
                    OutlinedButton.icon(
                      onPressed: sesion.ocupado
                          ? null
                          : () => _revocar(context, sesion),
                      icon: const Icon(Icons.gpp_bad_outlined),
                      label: const Text(Cadenas.revocarConsentimiento),
                    )
                  else
                    FilledButton.icon(
                      onPressed: sesion.ocupado
                          ? null
                          : () => _otorgar(context, sesion),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text(Cadenas.otorgarConsentimiento),
                    ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ---------------- Eliminacion de datos ----------------
                  Text(
                    Cadenas.eliminarMisDatosAviso,
                    style: textos.bodySmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: sesion.ocupado
                        ? null
                        : () => _eliminar(context, sesion),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: esquema.error,
                      side: BorderSide(color: esquema.error),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(Cadenas.eliminarMisDatos),
                  ),

                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: sesion.ocupado
                        ? null
                        : () => _cerrarSesion(context, sesion),
                    icon: const Icon(Icons.logout),
                    label: const Text(Cadenas.cerrarSesion),
                  ),

                  if (sesion.fallo != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        sesion.fallo!.mensaje,
                        style: textos.bodyMedium?.copyWith(
                          color: esquema.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  // -------------------------------------------------------------------

  Future<void> _otorgar(BuildContext context, SesionViewModel sesion) async {
    final mensajero = ScaffoldMessenger.of(context);
    if (await sesion.otorgarConsentimiento()) {
      mensajero.showSnackBar(
        const SnackBar(content: Text(Cadenas.consentimientoOtorgadoAviso)),
      );
    }
  }

  Future<void> _revocar(BuildContext context, SesionViewModel sesion) async {
    final mensajero = ScaffoldMessenger.of(context);
    final confirmado = await _confirmar(
      context,
      titulo: Cadenas.revocarConsentimiento,
      detalle: Cadenas.revocarConsentimientoAviso,
    );
    if (!confirmado) return;

    if (await sesion.revocarConsentimiento()) {
      mensajero.showSnackBar(
        const SnackBar(content: Text(Cadenas.consentimientoRevocadoAviso)),
      );
    }
  }

  Future<void> _eliminar(BuildContext context, SesionViewModel sesion) async {
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    final confirmado = await _confirmar(
      context,
      titulo: Cadenas.eliminarMisDatos,
      detalle: Cadenas.eliminarMisDatosAviso,
      destructivo: true,
    );
    if (!confirmado) return;

    if (await sesion.eliminarMisDatos()) {
      mensajero.showSnackBar(
        const SnackBar(content: Text(Cadenas.datosEliminados)),
      );
      navegador.pushNamedAndRemoveUntil(Rutas.inicioSesion, (_) => false);
    }
  }

  Future<void> _cerrarSesion(
    BuildContext context,
    SesionViewModel sesion,
  ) async {
    final navegador = Navigator.of(context);
    await sesion.cerrarSesion();
    navegador.pushNamedAndRemoveUntil(Rutas.inicioSesion, (_) => false);
  }

  Future<bool> _confirmar(
    BuildContext context, {
    required String titulo,
    required String detalle,
    bool destructivo = false,
  }) async {
    final esquema = Theme.of(context).colorScheme;
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Text(detalle),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text(Cadenas.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: destructivo
                ? TextButton.styleFrom(foregroundColor: esquema.error)
                : null,
            child: const Text(Cadenas.confirmar),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }
}

class _SinSesion extends StatelessWidget {
  const _SinSesion();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            Cadenas.subtituloInicioSesion,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(Rutas.inicioSesion, (_) => false),
            child: const Text(Cadenas.entrar),
          ),
        ],
      ),
    ),
  );
}
