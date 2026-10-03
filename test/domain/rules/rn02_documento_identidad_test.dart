import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/rules/rn02_documento_identidad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RN-02 — DNI', () {
    test('acepta un DNI de 8 digitos', () {
      final r = Rn02DocumentoIdentidad.validar(
        tipo: TipoDocumento.dni,
        numero: '12345678',
      );
      expect(r.cumple, isTrue);
      expect(r.regla, 'RN-02');
    });

    test('rechaza menos de 8 digitos', () {
      final r = Rn02DocumentoIdentidad.validar(
        tipo: TipoDocumento.dni,
        numero: '1234567',
      );
      expect(r.infringida, isTrue);
      expect(r.campo, 'numeroDocumento');
    });

    test('rechaza mas de 8 digitos', () {
      expect(
        Rn02DocumentoIdentidad.validar(
          tipo: TipoDocumento.dni,
          numero: '123456789',
        ).infringida,
        isTrue,
      );
    });

    test('rechaza letras', () {
      final r = Rn02DocumentoIdentidad.validar(
        tipo: TipoDocumento.dni,
        numero: '1234567A',
      );
      expect(r.infringida, isTrue);
      expect(r.mensaje, contains('numeros'));
    });

    test('rechaza el vacio', () {
      expect(
        Rn02DocumentoIdentidad.validar(
          tipo: TipoDocumento.dni,
          numero: '',
        ).infringida,
        isTrue,
      );
    });

    test('rechaza un documento con todos los digitos iguales', () {
      expect(
        Rn02DocumentoIdentidad.validar(
          tipo: TipoDocumento.dni,
          numero: '00000000',
        ).infringida,
        isTrue,
      );
      expect(
        Rn02DocumentoIdentidad.validar(
          tipo: TipoDocumento.dni,
          numero: '11111111',
        ).infringida,
        isTrue,
      );
    });

    test('tolera espacios, puntos y guiones', () {
      for (final entrada in <String>['12 345 678', '12.345.678', '12-345-678']) {
        expect(
          Rn02DocumentoIdentidad.validar(
            tipo: TipoDocumento.dni,
            numero: entrada,
          ).cumple,
          isTrue,
          reason: 'Deberia aceptar "$entrada"',
        );
      }
    });
  });

  group('RN-02 — Carne de extranjeria', () {
    test('acepta entre 9 y 12 caracteres alfanumericos', () {
      for (final entrada in <String>['123456789', 'AB1234567', '123456789012']) {
        expect(
          Rn02DocumentoIdentidad.validar(
            tipo: TipoDocumento.carneExtranjeria,
            numero: entrada,
          ).cumple,
          isTrue,
          reason: 'Deberia aceptar "$entrada"',
        );
      }
    });

    test('rechaza menos de 9 caracteres', () {
      expect(
        Rn02DocumentoIdentidad.validar(
          tipo: TipoDocumento.carneExtranjeria,
          numero: '12345678',
        ).infringida,
        isTrue,
      );
    });

    test('rechaza mas de 12 caracteres', () {
      expect(
        Rn02DocumentoIdentidad.validar(
          tipo: TipoDocumento.carneExtranjeria,
          numero: '1234567890123',
        ).infringida,
        isTrue,
      );
    });

    test('rechaza simbolos', () {
      expect(
        Rn02DocumentoIdentidad.validar(
          tipo: TipoDocumento.carneExtranjeria,
          numero: 'AB12345#9',
        ).infringida,
        isTrue,
      );
    });

    test('un DNI de 8 digitos no vale como carne de extranjeria', () {
      expect(
        Rn02DocumentoIdentidad.validar(
          tipo: TipoDocumento.carneExtranjeria,
          numero: '12345678',
        ).infringida,
        isTrue,
      );
    });
  });

  group('RN-02 — normalizacion', () {
    test('quita separadores y pasa a mayusculas', () {
      expect(Rn02DocumentoIdentidad.normalizar(' ab-12 34.5678 '), 'AB12345678');
    });
  });
}
