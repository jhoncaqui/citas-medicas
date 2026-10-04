import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../l10n/cadenas.dart';
import '../viewmodels/sesion_viewmodel.dart';
import 'inicio_screen.dart';
import 'inicio_sesion_screen.dart';

/// Pantalla raiz: decide que ve el paciente segun el estado de la sesion.
///
/// **RN-01** se aplica aqui como primera barrera: sin sesion activa no se
/// llega a las pantallas de gestion de citas. No es la unica barrera — las
/// operaciones protegidas vuelven a consultar la regla antes de tocar el
/// repositorio — pero evita mostrar una interfaz que el paciente no podria
/// usar.
class PuertaEntrada extends StatefulWidget {
  const PuertaEntrada({super.key});

  @override
  State<PuertaEntrada> createState() => _PuertaEntradaState();
}

class _PuertaEntradaState extends State<PuertaEntrada> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SesionViewModel>().restaurar();
    });
  }

  @override
  Widget build(BuildContext context) {
    // RNF-03: `select` acotado — solo se reconstruye al cambiar el estado de
    // sesion, no ante cada cambio del ViewModel (por ejemplo `ocupado`).
    final estado = context.select<SesionViewModel, EstadoSesion>(
      (vm) => vm.estado,
    );

    return switch (estado) {
      EstadoSesion.comprobando => const _Comprobando(),
      EstadoSesion.anonimo => const InicioSesionScreen(),
      EstadoSesion.autenticado => const InicioScreen(),
    };
  }
}

class _Comprobando extends StatelessWidget {
  const _Comprobando();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Semantics(
        label: Cadenas.semanticaCargando,
        liveRegion: true,
        child: const Center(child: CircularProgressIndicator()),
      ),
    ),
  );
}
