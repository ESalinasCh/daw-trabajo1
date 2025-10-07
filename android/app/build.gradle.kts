import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Lee el archivo .env para obtener la clave de API
val dotenv = Properties()
val dotenvFile = rootProject.file("../.env")
if (dotenvFile.exists()) {
    dotenvFile.inputStream().use { input ->
        val lines = input.bufferedReader().readLines().filter { it.contains('=') }
        val filteredContent = lines.joinToString("\n")
        dotenv.load(filteredContent.reader())
    }
}

// Lee el archivo local.properties para obtener la clave de API
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.reader())
}

// Resolve Flutter version properties safely: first check project extras, then local.properties, then defaults
fun findProp(name: String, local: Properties, default: String): String {
    // project.findProperty returns Any? or null
    val prop = if (project.hasProperty(name)) project.property(name) as String else null
    if (prop != null) return prop
    // check local.properties keys used by Flutter tooling (flutter.versionCode / flutter.versionName)
    val localKey = when (name) {
        "flutterVersionCode" -> "flutter.versionCode"
        "flutterVersionName" -> "flutter.versionName"
        else -> name
    }
    return local.getProperty(localKey) ?: default
}

val flutterVersionCode: String = findProp("flutterVersionCode", localProperties, "1")
val flutterVersionName: String = findProp("flutterVersionName", localProperties, "1.0.0")

android {
    namespace = "com.example.trabajo1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.example.trabajo1"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName

        // Usa la clave leída de .env
        manifestPlaceholders["googleMapsApiKey"] = dotenv.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies { }