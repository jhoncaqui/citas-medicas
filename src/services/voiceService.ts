// Servicio de Voz (Web Speech API: SpeechRecognition + SpeechSynthesis)

export interface VoiceRecognitionHandlers {
  onResult: (transcript: string, isFinal: boolean) => void;
  onError?: (error: string) => void;
  onStart?: () => void;
  onEnd?: () => void;
}

export class VoiceService {
  private static recognitionInstance: any = null;
  private static isListening: boolean = false;

  static isRecognitionSupported(): boolean {
    return typeof window !== 'undefined' && ('SpeechRecognition' in window || 'webkitSpeechRecognition' in window);
  }

  static isSynthesisSupported(): boolean {
    return typeof window !== 'undefined' && 'speechSynthesis' in window;
  }

  static startListening(handlers: VoiceRecognitionHandlers): boolean {
    if (!this.isRecognitionSupported()) {
      handlers.onError?.('El reconocimiento de voz no está soportado en este navegador.');
      return false;
    }

    try {
      this.stopListening();

      const SpeechRecognitionClass = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
      const recognition = new SpeechRecognitionClass();

      recognition.lang = 'es-PE'; // Español Perú / Latinoamericano
      recognition.continuous = false;
      recognition.interimResults = true;
      recognition.maxAlternatives = 1;

      recognition.onstart = () => {
        this.isListening = true;
        handlers.onStart?.();
      };

      recognition.onresult = (event: any) => {
        let interimTranscript = '';
        let finalTranscript = '';

        for (let i = event.resultIndex; i < event.results.length; ++i) {
          const trans = event.results[i][0].transcript;
          if (event.results[i].isFinal) {
            finalTranscript += trans;
          } else {
            interimTranscript += trans;
          }
        }

        if (finalTranscript.trim()) {
          handlers.onResult(finalTranscript.trim(), true);
        } else if (interimTranscript.trim()) {
          handlers.onResult(interimTranscript.trim(), false);
        }
      };

      recognition.onerror = (event: any) => {
        this.isListening = false;
        let mensaje = 'No se pudo reconocer la voz.';
        if (event.error === 'not-allowed') {
          mensaje = 'Permiso de micrófono denegado. Habilita el acceso en tu navegador.';
        } else if (event.error === 'no-speech') {
          mensaje = 'No se detectó voz. Vuelve a intentar.';
        } else if (event.error === 'audio-capture') {
          mensaje = 'No se detectó micrófono en tu dispositivo.';
        }
        handlers.onError?.(mensaje);
      };

      recognition.onend = () => {
        this.isListening = false;
        handlers.onEnd?.();
      };

      recognition.start();
      this.recognitionInstance = recognition;
      return true;
    } catch (err: any) {
      this.isListening = false;
      handlers.onError?.(err?.message || 'Error al iniciar reconocimiento de voz.');
      return false;
    }
  }

  static stopListening(): void {
    if (this.recognitionInstance) {
      try {
        this.recognitionInstance.abort();
      } catch (_) {}
      this.recognitionInstance = null;
    }
    this.isListening = false;
  }

  static getIsListening(): boolean {
    return this.isListening;
  }

  // Síntesis de voz (Text to Speech)
  static speak(text: string, onEnd?: () => void): void {
    if (!this.isSynthesisSupported()) return;

    try {
      window.speechSynthesis.cancel(); // Cancelar lo anterior

      // Limpiar texto para una locución natural
      const textoLimpio = text
        .replace(/[*_#`]/g, '')
        .replace(/\n+/g, ' ')
        .trim();

      if (!textoLimpio) return;

      const utterance = new SpeechSynthesisUtterance(textoLimpio);
      utterance.lang = 'es-PE';
      utterance.rate = 1.0;
      utterance.pitch = 1.0;

      // Buscar voz en español
      const voices = window.speechSynthesis.getVoices();
      const vozEs = voices.find(
        (v) => v.lang.startsWith('es') || v.lang.includes('Spanish')
      );
      if (vozEs) {
        utterance.voice = vozEs;
      }

      utterance.onend = () => {
        onEnd?.();
      };

      utterance.onerror = () => {
        onEnd?.();
      };

      window.speechSynthesis.speak(utterance);
    } catch (_) {
      onEnd?.();
    }
  }

  static stopSpeaking(): void {
    if (!this.isSynthesisSupported()) return;
    try {
      window.speechSynthesis.cancel();
    } catch (_) {}
  }
}
