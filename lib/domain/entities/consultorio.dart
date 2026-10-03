/// Consultorio dentro de una sede.
class Consultorio {
  const Consultorio({
    required this.id,
    required this.sedeId,
    required this.codigo,
    required this.piso,
  });

  final String id;
  final String sedeId;

  /// Codigo visible al paciente en el comprobante, por ejemplo `C-204`.
  final String codigo;

  final int piso;

  Consultorio copyWith({
    String? id,
    String? sedeId,
    String? codigo,
    int? piso,
  }) => Consultorio(
    id: id ?? this.id,
    sedeId: sedeId ?? this.sedeId,
    codigo: codigo ?? this.codigo,
    piso: piso ?? this.piso,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Consultorio &&
          other.id == id &&
          other.sedeId == sedeId &&
          other.codigo == codigo &&
          other.piso == piso;

  @override
  int get hashCode => Object.hash(id, sedeId, codigo, piso);

  @override
  String toString() => 'Consultorio($id, $codigo)';
}
