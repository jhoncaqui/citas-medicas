import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/inicio_sesion_viewmodel.dart';
import '../widgets/campo_texto.dart';
import '../widgets/logo_clinica.dart';

/// HU-02 — Inicio de sesion seguro.
///
/// El fallo se muestra con un unico mensaje generico: no distingue entre
/// documento no registrado y contrasena incorrecta.
class InicioSesionScreen extends StatelessWidget {
  const InicioSesionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InicioSesionViewModel>();
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    // Sin AppBar: es la primera pantalla que ve el paciente y el logo hace de
    // cabecera. Una barra con el titulo repetiria lo que el logo ya dice.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: <Widget>[
              // Espacio del logo de la clinica.
              const CabeceraConLogo(
                titulo: Cadenas.tituloInicioSesion,
                subtitulo: Cadenas.subtituloInicioSesion,
              ),

              CampoTexto(
                etiqueta: Cadenas.documentoOUsuario,
                error: vm.errorDe('numeroDocumento'),
                habilitado: !vm.ocupado,
                tipoTeclado: TextInputType.text,
                autofillHints: const <String>[AutofillHints.username],
                onChanged: vm.cambiarNumeroDocumento,
              ),
              CampoTexto(
                etiqueta: Cadenas.clave,
                error: vm.errorDe('clave'),
                habilitado: !vm.ocupado,
                esClave: true,
                autofillHints: const <String>[AutofillHints.password],
                onChanged: vm.cambiarClave,
              ),

              if (vm.mensajeFallo != null) ...<Widget>[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    vm.mensajeFallo!,
                    style: textos.bodyMedium?.copyWith(color: esquema.error),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              FilledButton(
                onPressed: vm.ocupado ? null : () => _enviar(context, vm),
                child: vm.ocupado
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(Cadenas.entrar),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: vm.ocupado
                    ? null
                    : () {
                        vm.limpiarFallo();
                        Navigator.of(context)
                            .pushReplacementNamed(Rutas.registro);
                      },
                child: const Text(Cadenas.noTengoCuenta),
              ),

              const SizedBox(height: 32),
              const PieDemostracion(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enviar(BuildContext context, InicioSesionViewModel vm) async {
    final navegador = Navigator.of(context);
    final exito = await vm.enviar();
    if (!exito) return;
    navegador.pushNamedAndRemoveUntil(Rutas.inicio, (_) => false);
  }
}
