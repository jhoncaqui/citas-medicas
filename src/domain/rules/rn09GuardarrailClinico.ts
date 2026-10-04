import { ResultadoRegla } from '../../types';
import { ConfigService } from '../../services/configService';
import { Resultado } from './resultadoRegla';

export const CODIGO_RN09 = 'RN-09';

export class Rn09GuardarrailClinico {
  private static readonly sintomas = [
    'dolor',
    'duele',
    'dolencia',
    'molestia',
    'malestar',
    'fiebre',
    'temperatura',
    'escalofrio',
    'tos',
    'gripe',
    'resfriado',
    'catarro',
    'mareo',
    'mareado',
    'vertigo',
    'desmayo',
    'nausea',
    'vomito',
    'vomitar',
    'diarrea',
    'estrenimiento',
    'sangrado',
    'sangre',
    'herida',
    'golpe',
    'fractura',
    'ardor',
    'arde',
    'ardiendo',
    'picazon',
    'comezon',
    'sarpullido',
    'roncha',
    'erupcion',
    'orinar',
    'hinchazon',
    'inflamacion',
    'inflamado',
    'ahogo',
    'falta de aire',
    'respirar',
    'palpitacion',
    'presion alta',
    'presion baja',
    'cansancio',
    'fatiga',
    'debilidad',
    'insomnio',
    'ansiedad',
    'depresion',
    'angustia',
    'sintoma',
    'sintomas',
    'enfermo',
    'enferma',
    'siento mal',
    'me siento',
    'tengo malestar',
  ];

  private static readonly peticionesDeOrientacion = [
    'que tengo',
    'que me pasa',
    'sera grave',
    'es grave',
    'que especialista',
    'que especialidad me',
    'a que especialista',
    'con quien me atiendo',
    'con que doctor debo',
    'que doctor necesito',
    'que me recomiendas',
    'que recomiendas',
    'me recomiendas',
    'que debo tomar',
    'que medicamento',
    'que pastilla',
    'es normal que',
    'diagnostico',
    'diagnosticar',
    'necesito un especialista para',
  ];

  static normalizar(texto: string): string {
    const conTilde = 'áéíóúàèìòùäëïöüâêîôûñ';
    const sinTilde = 'aeiouaeiouaeiouaeioun';

    let resultado = texto.toLowerCase();
    for (let i = 0; i < conTilde.length; i++) {
      resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
    }
    return resultado;
  }

  static requiereDerivacion(texto: string): boolean {
    return this.evaluar(texto).infringida;
  }

  static evaluar(texto: string): ResultadoRegla {
    // Si la opción de guardarraíl clínico está desactivada por el administrador, no bloquear
    if (typeof localStorage !== 'undefined') {
      const opciones = ConfigService.obtenerOpciones();
      if (!opciones.guardarailClinicoActivo) {
        return Resultado.valida(CODIGO_RN09);
      }
    }

    const normalizado = this.normalizar(texto);

    // Si el usuario claramente está solicitando agendar una cita o consulta con un médico,
    // NO se debe bloquear la reserva. El propósito de la app es precisamente conectar al paciente con el médico.
    const tieneIntencionReserva =
      normalizado.includes('cita') ||
      normalizado.includes('reservar') ||
      normalizado.includes('sacar') ||
      normalizado.includes('agendar') ||
      normalizado.includes('turno') ||
      normalizado.includes('consulta') ||
      normalizado.includes('atenderme') ||
      normalizado.includes('medicina') ||
      normalizado.includes('pediatria') ||
      normalizado.includes('cardiologia') ||
      normalizado.includes('dermatologia') ||
      normalizado.includes('doctor') ||
      normalizado.includes('medico');

    for (const frase of this.peticionesDeOrientacion) {
      if (normalizado.includes(frase)) {
        return Resultado.infringe(
          CODIGO_RN09,
          'El mensaje pide orientación clínica.'
        );
      }
    }

    // Solo derivar por síntoma si NO está pidiendo expresamente una cita o consulta
    if (!tieneIntencionReserva) {
      for (const sintoma of this.sintomas) {
        if (this.contienePalabra(normalizado, sintoma)) {
          return Resultado.infringe(
            CODIGO_RN09,
            'El mensaje describe un síntoma.'
          );
        }
      }
    }

    return Resultado.valida(CODIGO_RN09);
  }

  private static contienePalabra(texto: string, termino: string): boolean {
    if (termino.includes(' ')) return texto.includes(termino);
    const escaped = termino.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const patron = new RegExp(`(^|[^a-z0-9])${escaped}([^a-z0-9]|$)`);
    return patron.test(texto);
  }
}
