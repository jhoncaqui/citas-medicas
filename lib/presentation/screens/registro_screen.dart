import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../domain/entities/intencion_asistente.dart';
import '../../domain/rules/rn02_documento_identidad.dart';
import '../../domain/rules/validaciones_registro.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/registro_viewmodel.dart';
import '../widgets/campo_texto.dart';
import '../widgets/logo_clinica.dart';

/// HU-01 — Registro con validacion de documento de identidad.
class RegistroScreen extends StatelessWidget {
  const RegistroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroViewModel>();
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      // La barra solo lleva el boton de volver: el titulo ya esta en la
      // cabecera, junto al logo.
      appBar: AppBar(),
      // Seccion 12: edge-to-edge obligatorio en API 36.
      body: SafeArea(
        child: Semantics(
          label: Cadenas.semanticaFormularioRegistro,
          container: true,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              // Misma cabecera que el inicio de sesion: el logo mas pequeno,
              // porque aqui el formulario es largo y debe verse cuanto antes.
              const CabeceraConLogo(
                titulo: Cadenas.tituloRegistro,
                subtitulo: Cadenas.subtituloRegistro,
                altoLogo: 64,
              ),

              // RN-02 — tipo y numero de documento.
              _SelectorTipoDocumento(
                seleccionado: vm.tipoDocumento,
                onChanged: vm.cambiarTipoDocumento,
                habilitado: !vm.ocupado,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: Cadenas.numeroDocumento,
                error: vm.errorDe('numeroDocumento'),
                habilitado: !vm.ocupado,
                tipoTeclado: vm.tipoDocumento == TipoDocumento.dni
                    ? TextInputType.number
                    : TextInputType.text,
                // Se deja margen sobre la longitud exigida para que quepan
                // los separadores que el paciente pueda escribir o pegar
                // ("12 345 678"). RN-02 los normaliza despues; con el limite
                // justo, el campo truncaria el documento antes de validarlo.
                maxCaracteres: vm.tipoDocumento == TipoDocumento.dni
                    ? Rn02DocumentoIdentidad.longitudDni + 2
                    : Rn02DocumentoIdentidad.longitudMaximaCe + 2,
                textoAyuda: vm.tipoDocumento == TipoDocumento.dni
                    ? '8 digitos'
                    : 'Entre 9 y 12 caracteres',
                onChanged: vm.cambiarNumeroDocumento,
              ),

              CampoTexto(
                etiqueta: Cadenas.nombres,
                error: vm.errorDe('nombres'),
                habilitado: !vm.ocupado,
                tipoTeclado: TextInputType.name,
                autofillHints: const <String>[AutofillHints.givenName],
                onChanged: vm.cambiarNombres,
              ),
              CampoTexto(
                etiqueta: Cadenas.apellidos,
                error: vm.errorDe('apellidos'),
                habilitado: !vm.ocupado,
                tipoTeclado: TextInputType.name,
                autofillHints: const <String>[AutofillHints.familyName],
                onChanged: vm.cambiarApellidos,
              ),
              CampoTexto(
                etiqueta: Cadenas.correo,
                error: vm.errorDe('correo'),
                habilitado: !vm.ocupado,
                tipoTeclado: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                onChanged: vm.cambiarCorreo,
              ),
              CampoTexto(
                etiqueta: Cadenas.telefono,
                error: vm.errorDe('telefono'),
                habilitado: !vm.ocupado,
                tipoTeclado: TextInputType.phone,
                maxCaracteres: 9,
                textoAyuda: '9 digitos, empieza con 9',
                onChanged: vm.cambiarTelefono,
              ),
              CampoTexto(
                etiqueta: Cadenas.clave,
                error: vm.errorDe('clave'),
                habilitado: !vm.ocupado,
                esClave: true,
                textoAyuda:
                    'Minimo '
                    '${ValidacionesRegistro.longitudMinimaClave} caracteres',
                onChanged: vm.cambiarClave,
              ),
              CampoTexto(
                etiqueta: Cadenas.confirmarClave,
                error: vm.errorDe('confirmacionClave'),
                habilitado: !vm.ocupado,
                esClave: true,
                onChanged: vm.cambiarConfirmacionClave,
              ),

              const SizedBox(height: 8),
              _Consentimiento(
                aceptado: vm.consentimientoAceptado,
                error: vm.errorDe('consentimiento'),
                habilitado: !vm.ocupado,
                onChanged: vm.cambiarConsentimiento,
              ),

              if (vm.mensajeFallo != null) ...<Widget>[
                const SizedBox(height: 16),
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
                    : const Text(Cadenas.crearCuenta),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: vm.ocupado
                    ? null
                    : () =>
                          Navigator.of(context)
                              .pushReplacementNamed(Rutas.inicioSesion),
                child: const Text(Cadenas.yaTengoCuenta),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enviar(BuildContext context, RegistroViewModel vm) async {
    final navegador = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);

    final exito = await vm.enviar();
    if (!exito) return;

    mensajero.showSnackBar(
      const SnackBar(content: Text(Cadenas.registroCorrecto)),
    );
    navegador.pushNamedAndRemoveUntil(Rutas.inicio, (_) => false);
  }
}

/// RN-02 — Seleccion entre DNI y carne de extranjeria.
class _SelectorTipoDocumento extends StatelessWidget {
  const _SelectorTipoDocumento({
    required this.seleccionado,
    required this.onChanged,
    required this.habilitado,
  });

  final TipoDocumento seleccionado;
  final ValueChanged<TipoDocumento> onChanged;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          Cadenas.tipoDocumento,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<TipoDocumento>(
          segments: <ButtonSegment<TipoDocumento>>[
            for (final tipo in TipoDocumento.registrables)
              ButtonSegment<TipoDocumento>(
                value: tipo,
                label: Text(tipo.etiqueta),
              ),
          ],
          selected: <TipoDocumento>{seleccionado},
          onSelectionChanged: habilitado
              ? (seleccion) => onChanged(seleccion.first)
              : null,
        ),
      ],
    );
  }
}

/// RN-10 — Consentimiento informado, explicito y nunca premarcado.
class _Consentimiento extends StatelessWidget {
  const _Consentimiento({
    required this.aceptado,
    required this.error,
    required this.habilitado,
    required this.onChanged,
  });

  final bool aceptado;
  final String? error;
  final bool habilitado;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // CheckboxListTile ya expone rol de casilla y estado marcado al
        // lector de pantalla, y respeta el area tactil minima del tema.
        CheckboxListTile(
          value: aceptado,
          onChanged: habilitado ? (v) => onChanged(v ?? false) : null,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(Cadenas.consentimientoEtiqueta, style: textos.bodyLarge),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              Cadenas.consentimientoDetalle,
              style: textos.bodySmall?.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
          ),
          isThreeLine: true,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: textos.bodySmall?.copyWith(color: esquema.error),
              ),
            ),
          ),
      ],
    );
  }
}
