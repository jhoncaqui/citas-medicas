import { ResultadoRegla } from '../../types';

export const Resultado = {
  valida(regla: string): ResultadoRegla {
    return { cumple: true, infringida: false, regla };
  },
  infringe(regla: string, mensaje: string, campo?: string): ResultadoRegla {
    return { cumple: false, infringida: true, regla, mensaje, campo };
  },
};
