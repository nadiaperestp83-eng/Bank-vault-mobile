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
}

subprojects {
    val configureAndroid: Project.() -> Unit = {
        val androidExtension = extensions.findByName("android")
        if (androidExtension != null) {
            try {
                val getNamespace = androidExtension.javaClass.getMethod("getNamespace")
                val setNamespace = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
                var namespace = getNamespace.invoke(androidExtension)
                
                if (namespace == null) {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestContent = manifestFile.readText()
                        val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestContent)
                        if (packageMatch != null) {
                            namespace = packageMatch.groupValues[1]
                        }
                    }
                }

                if (namespace == null) {
                    namespace = "com.vaultos.${project.name.replace("-", "_")}"
                }
                
                setNamespace.invoke(androidExtension, namespace)

                try {
                    val setCompileSdk = androidExtension.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                    setCompileSdk.invoke(androidExtension, 36)
                } catch (e: Exception) {
                    try {
                        val setCompileSdk = androidExtension.javaClass.getMethod("compileSdk", Int::class.javaPrimitiveType)
                        setCompileSdk.invoke(androidExtension, 36)
                    } catch (e2: Exception) {}
                }
            } catch (e: Exception) {
                // Ignore if methods don't exist
            }
        }
    }

    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate { configureAndroid() }
    }
}

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
