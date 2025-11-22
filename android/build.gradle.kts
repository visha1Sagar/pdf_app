allprojects {
    repositories {
        google()
        mavenCentral()
    }
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

    // Force all subprojects (plugins) to use the same compile SDK version
    val configureAndroid = {
        project.extensions.findByName("android")?.let { android ->
            try {
                val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                setCompileSdkVersion.invoke(android, 36)
            } catch (e: Exception) {
                try {
                    val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                    setCompileSdkVersion.invoke(android, "android-36")
                } catch (e2: Exception) {
                    // Ignore
                }
            }
        }
    }

    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }

    if (project.name == "isar_flutter_libs") {
        val configureIsar = {
            project.extensions.findByName("android")?.let { android ->
                try {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, "dev.isar.isar_flutter_libs")
                } catch (e: Exception) {
                    println("Failed to set namespace for isar_flutter_libs: ${e.message}")
                }
            }
        }

        if (project.state.executed) {
            configureIsar()
        } else {
            project.afterEvaluate {
                configureIsar()
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


