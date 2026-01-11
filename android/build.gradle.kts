// (Removed duplicate com.google.gms.google-services plugin declaration)

allprojects {
    buildscript {
        repositories {
            google()
            maven { url = uri("https://repo1.maven.org/maven2/") }
            all {
                if (this is MavenArtifactRepository && url.toString().startsWith("https://repo.maven.apache.org/maven2")) {
                    url = uri("https://repo1.maven.org/maven2/")
                }
            }
        }
    }
    repositories {
        google()
        maven { url = uri("https://repo1.maven.org/maven2/") }
        all {
            if (this is MavenArtifactRepository && url.toString().startsWith("https://repo.maven.apache.org/maven2")) {
                url = uri("https://repo1.maven.org/maven2/")
            }
        }
    }
}



val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
