// android/build.gradle.kts (raíz)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.1") 
        classpath("com.google.gms:google-services:4.4.0")  
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Cambia la carpeta de build para Flutter (opcional)
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

// Limpiar builds
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
