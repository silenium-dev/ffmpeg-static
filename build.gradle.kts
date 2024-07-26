import dev.silenium.libs.jni.NativePlatform
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinVersion

buildscript {
    repositories {
        maven("https://reposilite.silenium.dev/releases") {
            name = "silenium-releases"
        }
    }
    dependencies {
        classpath(libs.jni.utils)
    }
}

plugins {
    alias(libs.plugins.kotlin)
    `maven-publish`
}

group = "dev.silenium.libs.ffmpeg"
version = findProperty("deploy.version") as String? ?: "0.0.0-SNAPSHOT"

repositories {
    mavenCentral()
    maven("https://reposilite.silenium.dev/releases") {
        name = "silenium-releases"
    }
}

dependencies {
    implementation(libs.jni.utils)
}

val withGPL: Boolean = findProperty("ffmpeg.gpl")?.toString()?.toBoolean() ?: false
val platformExtension = "-gpl".takeIf { withGPL }.orEmpty()
val platform = NativePlatform.platform(platformExtension)

val compileNative by tasks.registering(Exec::class) {
    commandLine(
        "bash",
        layout.projectDirectory.file("cppbuild.sh").asFile.absolutePath,
        "-extension", platform.extension,
        "-platform", platform.osArch,
        "install", "ffmpeg",
    )
    workingDir(layout.projectDirectory.asFile)

    inputs.property("platform", platform)
    inputs.files(layout.projectDirectory.files("cppbuild.sh"))
    inputs.files(layout.projectDirectory.files("detect-platform.sh"))
    inputs.files(layout.projectDirectory.files("ffmpeg/cppbuild.sh"))
    inputs.files(layout.projectDirectory.files("ffmpeg/*.patch"))
    inputs.files(layout.projectDirectory.files("ffmpeg/*.diff"))
    outputs.dir(layout.projectDirectory.dir("ffmpeg/cppbuild/${platform}"))
    outputs.cacheIf { true }
}

tasks.processResources {
    val platform = NativePlatform.platform(platformExtension)

    from(compileNative.get().outputs.files) {
        include("lib/*.so")
        include("lib/*.dll")
        include("lib/*.dylib")
        eachFile {
            path = "natives/$platform/$name"
        }
        into("natives/$platform/")
    }
}

val zipBuild by tasks.registering(Zip::class) {
    from(compileNative.get().outputs.files) {
        include("bin/**/*")
        include("include/**/*")
        include("lib/**/*")
        include("share/**/*")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_1_8
        languageVersion = KotlinVersion.KOTLIN_1_7
    }
    jvmToolchain(8)
}

java {
    withSourcesJar()
}

publishing {
    publications {
        create<MavenPublication>("native${platform.capitalized}") {
            from(components["java"])
            artifact(zipBuild)
            artifactId = "ffmpeg-natives-${platform}"
        }
    }

    repositories {
        maven(System.getenv("REPOSILITE_URL") ?: "https://reposilite.silenium.dev/snapshots") {
            name = "reposilite"
            credentials {
                username =
                    System.getenv("REPOSILITE_USERNAME") ?: project.findProperty("reposiliteUser") as String? ?: ""
                password =
                    System.getenv("REPOSILITE_PASSWORD") ?: project.findProperty("reposilitePassword") as String? ?: ""
            }
        }
    }
}
