// android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: java.io.File = rootProject.layout.buildDirectory.dir("../../build").get().asFile
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.resolve(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)

    // Workaround for old plugins (e.g. image_gallery_saver) that don't declare an AGP namespace.
    afterEvaluate {
        val androidExtension = project.extensions.findByType(
            com.android.build.gradle.BaseExtension::class.java,
        )
        if (androidExtension != null && androidExtension.namespace == null) {
            androidExtension.namespace = project.group.toString()
        }

        // Align JVM target for old plugins that ship inconsistent Java/Kotlin targets.
        project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java)
            .configureEach {
                kotlinOptions.jvmTarget = "17"
            }
        androidExtension?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}