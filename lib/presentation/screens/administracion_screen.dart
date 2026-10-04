import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/especialidad.dart';
import '../../domain/entities/profesional.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/administracion_viewmodel.dart';

/// Gestion del catalogo por el personal de administracion (CRUD).
///
/// Dos pestañas: especialidades y profesionales. Cada una lista los registros
/// y permite darlos de alta, editarlos y eliminarlos. Todas las escrituras
/// pasan por RN-01 en el ViewModel, no solo por la navegacion.
class AdministracionScreen extends StatefulWidget {
  const AdministracionScreen({super.key});

  @override
  State<AdministracionScreen> createState() => _AdministracionScreenState();
}

class _AdministracionScreenState extends State<AdministracionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdministracionViewModel>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdministracionViewModel>();

    // RN-01: si la cuenta no es de administracion, no se muestra el catalogo.
    if (!vm.puedeGestionar) {
      return Scaffold(
        appBar: AppBar(title: const Text(Cadenas.tituloAdministracion)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              vm.impedimento ?? Cadenas.errorGenerico,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(Cadenas.tituloAdministracion),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: Cadenas.adminPestanaEspecialidades),
              Tab(text: Cadenas.adminPestanaProfesionales),
            ],
          ),
        ),
        body: SafeArea(
          child: vm.cargando
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: <Widget>[
                    if (vm.ocupado) const LinearProgressIndicator(),
                    Expanded(
                      child: TabBarView(
                        children: <Widget>[
                          _ListaEspecialidades(vm: vm),
                          _ListaProfesionales(vm: vm),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: _BotonAgregar(vm: vm),
      ),
    );
  }
}

/// El FAB cambia segun la pestaña activa.
class _BotonAgregar extends StatelessWidget {
  const _BotonAgregar({required this.vm});

  final AdministracionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final indice = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: indice,
      builder: (context, _) {
        final enEspecialidades = indice.index == 0;
        return FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: Text(
            enEspecialidades
                ? Cadenas.adminNuevaEspecialidad
                : Cadenas.adminNuevoProfesional,
          ),
          onPressed: () {
            if (enEspecialidades) {
              _abrirFormularioEspecialidad(context, vm);
            } else {
              if (vm.especialidades.isEmpty) {
                _aviso(context, Cadenas.adminNecesitaEspecialidad);
                return;
              }
              _abrirFormularioProfesional(context, vm);
            }
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Lista de especialidades
// ---------------------------------------------------------------------

class _ListaEspecialidades extends StatelessWidget {
  const _ListaEspecialidades({required this.vm});

  final AdministracionViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.especialidades.isEmpty) {
      return const _Vacio(mensaje: Cadenas.adminSinEspecialidades);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: vm.especialidades.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final especialidad = vm.especialidades[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.medical_services_outlined),
            title: Text(especialidad.nombre),
            subtitle: Text(
              especialidad.activa
                  ? especialidad.descripcion
                  : '${Cadenas.adminInactiva} · ${especialidad.descripcion}',
            ),
            isThreeLine: true,
            trailing: _MenuRegistro(
              onEditar: () =>
                  _abrirFormularioEspecialidad(context, vm, especialidad),
              onEliminar: () => _confirmarEliminar(
                context,
                vm: vm,
                mensaje: Cadenas.adminConfirmarEliminarEspecialidad(
                  especialidad.nombre,
                ),
                alEliminar: () => vm.eliminarEspecialidad(especialidad.id),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Lista de profesionales
// ---------------------------------------------------------------------

class _ListaProfesionales extends StatelessWidget {
  const _ListaProfesionales({required this.vm});

  final AdministracionViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.profesionales.isEmpty) {
      return const _Vacio(mensaje: Cadenas.adminSinProfesionales);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: vm.profesionales.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final profesional = vm.profesionales[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(profesional.nombreCompleto),
            subtitle: Text(
              '${vm.nombreEspecialidad(profesional.especialidadId)} · '
              '${profesional.colegiatura}',
            ),
            trailing: _MenuRegistro(
              onEditar: () =>
                  _abrirFormularioProfesional(context, vm, profesional),
              onEliminar: () => _confirmarEliminar(
                context,
                vm: vm,
                mensaje: Cadenas.adminConfirmarEliminarProfesional(
                  profesional.nombreCompleto,
                ),
                alEliminar: () => vm.eliminarProfesional(profesional.id),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Menu de acciones (editar / eliminar) de cada registro.
class _MenuRegistro extends StatelessWidget {
  const _MenuRegistro({required this.onEditar, required this.onEliminar});

  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    onSelected: (valor) {
      if (valor == 'editar') onEditar();
      if (valor == 'eliminar') onEliminar();
    },
    itemBuilder: (_) => <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'editar',
        child: ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text(Cadenas.adminEditar),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'eliminar',
        child: ListTile(
          leading: Icon(Icons.delete_outline),
          title: Text(Cadenas.adminEliminar),
        ),
      ),
    ],
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------
// Formularios (alta y edicion)
// ---------------------------------------------------------------------

Future<void> _abrirFormularioEspecialidad(
  BuildContext context,
  AdministracionViewModel vm, [
  Especialidad? especialidad,
]) async {
  final mensajero = ScaffoldMessenger.of(context);
  final guardado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ChangeNotifierProvider<AdministracionViewModel>.value(
      value: vm,
      child: _FormularioEspecialidad(especialidad: especialidad),
    ),
  );
  if (guardado ?? false) {
    mensajero.showSnackBar(
      const SnackBar(content: Text(Cadenas.adminGuardado)),
    );
  }
}

Future<void> _abrirFormularioProfesional(
  BuildContext context,
  AdministracionViewModel vm, [
  Profesional? profesional,
]) async {
  final mensajero = ScaffoldMessenger.of(context);
  final guardado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ChangeNotifierProvider<AdministracionViewModel>.value(
      value: vm,
      child: _FormularioProfesional(profesional: profesional),
    ),
  );
  if (guardado ?? false) {
    mensajero.showSnackBar(
      const SnackBar(content: Text(Cadenas.adminGuardado)),
    );
  }
}

class _FormularioEspecialidad extends StatefulWidget {
  const _FormularioEspecialidad({this.especialidad});

  final Especialidad? especialidad;

  @override
  State<_FormularioEspecialidad> createState() =>
      _FormularioEspecialidadState();
}

class _FormularioEspecialidadState extends State<_FormularioEspecialidad> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late bool _activa;

  bool get _esEdicion => widget.especialidad != null;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.especialidad?.nombre ?? '');
    _descripcion = TextEditingController(
      text: widget.especialidad?.descripcion ?? '',
    );
    _activa = widget.especialidad?.activa ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdministracionViewModel>();
    return _MarcoFormulario(
      titulo: _esEdicion
          ? Cadenas.adminEditarEspecialidad
          : Cadenas.adminNuevaEspecialidad,
      formKey: _formKey,
      ocupado: vm.ocupado,
      fallo: vm.fallo?.mensaje,
      campos: <Widget>[
        TextFormField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: Cadenas.adminCampoNombre,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? Cadenas.adminErrorNombreVacio
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descripcion,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: Cadenas.adminCampoDescripcion,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(Cadenas.adminCampoActiva),
          value: _activa,
          onChanged: (v) => setState(() => _activa = v),
        ),
      ],
      onGuardar: () async {
        if (!(_formKey.currentState?.validate() ?? false)) return;
        final ok = await vm.guardarEspecialidad(
          id: widget.especialidad?.id,
          nombre: _nombre.text,
          descripcion: _descripcion.text,
          activa: _activa,
        );
        if (ok && context.mounted) Navigator.of(context).pop(true);
      },
    );
  }
}

class _FormularioProfesional extends StatefulWidget {
  const _FormularioProfesional({this.profesional});

  final Profesional? profesional;

  @override
  State<_FormularioProfesional> createState() => _FormularioProfesionalState();
}

class _FormularioProfesionalState extends State<_FormularioProfesional> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombres;
  late final TextEditingController _apellidos;
  late final TextEditingController _colegiatura;
  String? _especialidadId;

  bool get _esEdicion => widget.profesional != null;

  @override
  void initState() {
    super.initState();
    _nombres = TextEditingController(text: widget.profesional?.nombres ?? '');
    _apellidos = TextEditingController(
      text: widget.profesional?.apellidos ?? '',
    );
    _colegiatura = TextEditingController(
      text: widget.profesional?.colegiatura ?? '',
    );
    _especialidadId = widget.profesional?.especialidadId;
  }

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _colegiatura.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdministracionViewModel>();
    // Si la especialidad guardada ya no existe, se deja sin seleccion.
    final especialidades = vm.especialidades;
    final valorValido =
        especialidades.any((e) => e.id == _especialidadId)
        ? _especialidadId
        : null;

    return _MarcoFormulario(
      titulo: _esEdicion
          ? Cadenas.adminEditarProfesional
          : Cadenas.adminNuevoProfesional,
      formKey: _formKey,
      ocupado: vm.ocupado,
      fallo: vm.fallo?.mensaje,
      campos: <Widget>[
        TextFormField(
          controller: _nombres,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: Cadenas.adminCampoNombres,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? Cadenas.adminErrorNombresVacio
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _apellidos,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: Cadenas.adminCampoApellidos,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? Cadenas.adminErrorApellidosVacio
              : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: valorValido,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: Cadenas.adminCampoEspecialidad,
          ),
          items: <DropdownMenuItem<String>>[
            for (final e in especialidades)
              DropdownMenuItem<String>(value: e.id, child: Text(e.nombre)),
          ],
          onChanged: (v) => setState(() => _especialidadId = v),
          validator: (v) =>
              (v == null) ? Cadenas.adminErrorEspecialidadVacia : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _colegiatura,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: Cadenas.adminCampoColegiatura,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? Cadenas.adminErrorColegiaturaVacia
              : null,
        ),
      ],
      onGuardar: () async {
        if (!(_formKey.currentState?.validate() ?? false)) return;
        final ok = await vm.guardarProfesional(
          id: widget.profesional?.id,
          nombres: _nombres.text,
          apellidos: _apellidos.text,
          especialidadId: _especialidadId!,
          colegiatura: _colegiatura.text,
        );
        if (ok && context.mounted) Navigator.of(context).pop(true);
      },
    );
  }
}

/// Estructura comun de los formularios: titulo, campos, error y botones.
class _MarcoFormulario extends StatelessWidget {
  const _MarcoFormulario({
    required this.titulo,
    required this.formKey,
    required this.campos,
    required this.onGuardar,
    required this.ocupado,
    this.fallo,
  });

  final String titulo;
  final GlobalKey<FormState> formKey;
  final List<Widget> campos;
  final Future<void> Function() onGuardar;
  final bool ocupado;
  final String? fallo;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...campos,
              if (fallo != null) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  fallo!,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: esquema.error),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ocupado
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text(Cadenas.adminCancelar),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: ocupado ? null : onGuardar,
                      child: ocupado
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(Cadenas.adminGuardar),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------

Future<void> _confirmarEliminar(
  BuildContext context, {
  required AdministracionViewModel vm,
  required String mensaje,
  required Future<bool> Function() alEliminar,
}) async {
  final mensajero = ScaffoldMessenger.of(context);
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text(Cadenas.adminConfirmarEliminarTitulo),
      content: Text(mensaje),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(Cadenas.adminCancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(Cadenas.adminEliminar),
        ),
      ],
    ),
  );

  if (confirmado ?? false) {
    final ok = await alEliminar();
    mensajero.showSnackBar(
      SnackBar(
        content: Text(
          ok ? Cadenas.adminEliminado : (vm.fallo?.mensaje ?? Cadenas.errorGenerico),
        ),
      ),
    );
  }
}

void _aviso(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
}
