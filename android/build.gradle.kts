buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Pasta de build customizada do Flutter (mantém performance e organização)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory =
        newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// garante avaliação correta dos módulos
subprojects {
    project.evaluationDependsOn(":app")
}

// task de clean padrão
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}