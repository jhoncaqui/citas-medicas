import 'excepciones.dart';

/// Resultado tipado: obliga a la capa que consume a tratar el fallo de forma
/// explicita, en lugar de propagar excepciones hasta la interfaz.
sealed class Resultado<T> {
  const Resultado();

  const factory Resultado.exito(T valor) = Exito<T>;
  const factory Resultado.fallo(FalloApp fallo) = Fallo<T>;

  bool get esExito => this is Exito<T>;
  bool get esFallo => this is Fallo<T>;

  /// Valor si hubo exito, `null` si hubo fallo.
  T? get valorONull => switch (this) {
    Exito<T>(:final valor) => valor,
    Fallo<T>() => null,
  };

  /// Fallo si lo hubo, `null` si hubo exito.
  FalloApp? get falloONull => switch (this) {
    Exito<T>() => null,
    Fallo<T>(:final fallo) => fallo,
  };

  /// Reduce ambas ramas a un unico valor.
  R when<R>({
    required R Function(T valor) exito,
    required R Function(FalloApp fallo) fallo,
  }) => switch (this) {
    Exito<T>(valor: final v) => exito(v),
    Fallo<T>(fallo: final f) => fallo(f),
  };

  /// Transforma el valor conservando el fallo.
  Resultado<R> map<R>(R Function(T valor) transformar) => switch (this) {
    Exito<T>(:final valor) => Exito<R>(transformar(valor)),
    Fallo<T>(:final fallo) => Fallo<R>(fallo),
  };
}

final class Exito<T> extends Resultado<T> {
  const Exito(this.valor);
  final T valor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Exito<T> && other.valor == valor);

  @override
  int get hashCode => valor.hashCode;
}

final class Fallo<T> extends Resultado<T> {
  const Fallo(this.fallo);
  final FalloApp fallo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Fallo<T> && other.fallo == fallo);

  @override
  int get hashCode => fallo.hashCode;
}
