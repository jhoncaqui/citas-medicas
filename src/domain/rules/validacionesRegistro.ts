import { ResultadoRegla } from '../../types';
import { Resultado } from './resultadoRegla';

export const CODIGO_VAL = 'VAL';

export class ValidacionesRegistro {
  static readonly longitudMinimaClave = 8;
  private static readonly regexCorreo = /^[\w.!#$%&*+/=?^`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$/;
  private static readonly regexTelefono = /^9\d{8}$/;

  static validarNombres(valor: string): ResultadoRegla {
    const limpio = valor.trim();
    if (!limpio) {
      return Resultado.infringe(CODIGO_VAL, 'Ingresa tus nombres.', 'nombres');
    }
    if (limpio.length < 2) {
      return Resultado.infringe(CODIGO_VAL, 'Ingresa tus nombres completos.', 'nombres');
    }
    return Resultado.valida(CODIGO_VAL);
  }

  static validarApellidos(valor: string): ResultadoRegla {
    const limpio = valor.trim();
    if (!limpio) {
      return Resultado.infringe(CODIGO_VAL, 'Ingresa tus apellidos.', 'apellidos');
    }
    if (limpio.length < 2) {
      return Resultado.infringe(CODIGO_VAL, 'Ingresa tus apellidos completos.', 'apellidos');
    }
    return Resultado.valida(CODIGO_VAL);
  }

  static validarCorreo(valor: string): ResultadoRegla {
    const limpio = valor.trim().toLowerCase();
    if (!limpio) {
      return Resultado.infringe(CODIGO_VAL, 'Ingresa tu correo electrónico.', 'correo');
    }
    if (!this.regexCorreo.test(limpio)) {
      return Resultado.infringe(CODIGO_VAL, 'El correo electrónico no tiene un formato válido.', 'correo');
    }
    return Resultado.valida(CODIGO_VAL);
  }

  static validarTelefono(valor: string): ResultadoRegla {
    const limpio = valor.replace(/[\s\-()]/g, '');
    if (!limpio) {
      return Resultado.infringe(CODIGO_VAL, 'Ingresa tu número de celular.', 'telefono');
    }
    if (!this.regexTelefono.test(limpio)) {
      return Resultado.infringe(CODIGO_VAL, 'El celular debe tener 9 dígitos y empezar con 9.', 'telefono');
    }
    return Resultado.valida(CODIGO_VAL);
  }

  static validarClave(valor: string): ResultadoRegla {
    if (!valor) {
      return Resultado.infringe(CODIGO_VAL, 'Ingresa una contraseña.', 'clave');
    }
    if (valor.length < this.longitudMinimaClave) {
      return Resultado.infringe(
        CODIGO_VAL,
        `La contraseña debe tener al menos ${this.longitudMinimaClave} caracteres.`,
        'clave'
      );
    }
    return Resultado.valida(CODIGO_VAL);
  }

  static validarConfirmacionClave(clave: string, confirmacion: string): ResultadoRegla {
    if (!confirmacion) {
      return Resultado.infringe(CODIGO_VAL, 'Repite la contraseña.', 'confirmacionClave');
    }
    if (clave !== confirmacion) {
      return Resultado.infringe(CODIGO_VAL, 'Las contraseñas no coinciden.', 'confirmacionClave');
    }
    return Resultado.valida(CODIGO_VAL);
  }
}
