allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// El error indica que el plugin ya está en el classpath con versión 4.3.15.
// Esto suele pasar si algún subproyecto o configuración global lo fuerza.
// Eliminamos la declaración explicita de versión en el bloque plugins para usar la resuelta por el classpath,
// o intentamos alinearla. Sin embargo, la forma más segura si ya está en el classpath es declararlo sin versión
// o intentar ajustar a la versión que dice el error si es un conflicto de resolución.
// Probaremos usar la versión que el error dice que ya está cargada (4.3.15) o remover la versión del bloque.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // A veces es necesario declarar la dependencia del classpath explícitamente en buildscript
        // para evitar conflictos en el bloque plugins {} moderno si hay mezcla de estilos.
        classpath("com.google.gms:google-services:4.4.4")
    }
}

// Revertimos a la sintaxis de plugins pero intentando no chocar.
// Si el error persiste, es porque Flutter a veces inyecta dependencias.
// Vamos a probar alineando a la versión que el error menciona para evitar el conflicto.

plugins {
    id("com.google.gms.google-services") version "4.3.15" apply false
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
