import { ResultadoRegla, TipoDocumento } from '../../types';
import { Resultado } from './resultadoRegla';

export const CODIGO_RN02 = 'RN-02';

export class Rn02DocumentoIdentidad {
  static readonly longitudDni = 8;
  static readonly longitudMinimaCe = 9;
  static readonly longitudMaximaCe = 12;

  private static readonly soloDigitos = /^\d+$/;
  private static readonly alfanumerico = /^[A-Za-z0-9]+$/;

  static normalizar(valor: string): string {
    return valor.replace(/[\s\-.]/g, '').toUpperCase();
  }

  static validar(tipo: TipoDocumento, numero: string): ResultadoRegla {
    const limpio = this.normalizar(numero);

    if (!limpio) {
      return Resultado.infringe(
        CODIGO_RN02,
        'Ingresa tu número de documento.',
        'numeroDocumento'
      );
    }

    switch (tipo) {
      case 'DNI':
        return this.validarDni(limpio);
      case 'CE':
        return this.validarCarneExtranjeria(limpio);
      case 'USR':
        return Resultado.infringe(
          CODIGO_RN02,
          'Las cuentas de usuario no se registran desde la aplicación.',
          'numeroDocumento'
        );
      default:
        return Resultado.infringe(CODIGO_RN02, 'Tipo de documento no válido.', 'numeroDocumento');
    }
  }

  private static validarDni(numero: string): ResultadoRegla {
    if (!this.soloDigitos.test(numero)) {
      return Resultado.infringe(
        CODIGO_RN02,
        'El DNI solo puede contener números.',
        'numeroDocumento'
      );
    }

    if (numero.length !== this.longitudDni) {
      return Resultado.infringe(
        CODIGO_RN02,
        `El DNI debe tener ${this.longitudDni} dígitos.`,
        'numeroDocumento'
      );
    }

    // Documento con todos los dígitos iguales no es válido
    const digitosUnicos = new Set(numero.split(''));
    if (digitosUnicos.size === 1) {
      return Resultado.infringe(
        CODIGO_RN02,
        'El número de DNI no es válido.',
        'numeroDocumento'
      );
    }

    return Resultado.valida(CODIGO_RN02);
  }

  private static validarCarneExtranjeria(numero: string): ResultadoRegla {
    if (!this.alfanumerico.test(numero)) {
      return Resultado.infringe(
        CODIGO_RN02,
        'El carné de extranjería solo admite letras y números.',
        'numeroDocumento'
      );
    }

    if (numero.length < this.longitudMinimaCe || numero.length > this.longitudMaximaCe) {
      return Resultado.infringe(
        CODIGO_RN02,
        `El carné de extranjería debe tener entre ${this.longitudMinimaCe} y ${this.longitudMaximaCe} caracteres.`,
        'numeroDocumento'
      );
    }

    return Resultado.valida(CODIGO_RN02);
  }
}
