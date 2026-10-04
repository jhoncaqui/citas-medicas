import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------
// Credenciales fuera del control de versiones (seccion 15 del prompt).
//
// `key.properties` (firma) y `local.properties` (clave de Maps) estan en
// .gitignore. Si no existen, el proyecto compila igual: el AAB sale firmado
// con la clave de depuracion y el mapa no se muestra, que es exactamente lo
// que hace la bandera `USAR_MAPAS=false`.
// ---------------------------------------------------------------------

val propiedadesFirma = Properties()
val archivoFirma = rootProject.file("key.properties")
val hayFirmaPropia = archivoFirma.exists()
if (hayFirmaPropia) {
    propiedadesFirma.load(FileInputStream(archivoFirma))
}

val propiedadesLocales = Properties()
val archivoLocal = rootProject.file("local.properties")
if (archivoLocal.exists()) {
    propiedadesLocales.load(FileInputStream(archivoLocal))
}
val claveMaps: String = propiedadesLocales.getProperty("MAPS_API_KEY") ?: ""

android {
    namespace = "pe.edu.upn.citas.citas_medicas_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "pe.edu.upn.citas.citas_medicas_app"

        // Android 8.0. Decision documentada de ODS 12: no excluir terminales
        // de gama de entrada. NO subir este valor.
        minSdk = 26

        // Android 16. Exigido por Google Play desde el 31/08/2026.
        // Al apuntar a API 36 el modo edge-to-edge no se puede desactivar:
        // toda pantalla debe envolverse en SafeArea.
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // La clave de Google Maps entra por el manifiesto desde
        // local.properties. Vacia por defecto: nunca se versiona.
        manifestPlaceholders["mapsApiKey"] = claveMaps
    }

    signingConfigs {
        if (hayFirmaPropia) {
            create("release") {
                keyAlias = propiedadesFirma.getProperty("keyAlias")
                keyPassword = propiedadesFirma.getProperty("keyPassword")
                storeFile = propiedadesFirma.getProperty("storeFile")?.let { file(it) }
                storePassword = propiedadesFirma.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Con `key.properties` presente se firma con la clave del equipo.
            // Sin el, se usa la de depuracion para que `flutter build` siga
            // funcionando: un AAB asi NO es publicable en Google Play.
            signingConfig = if (hayFirmaPropia) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
