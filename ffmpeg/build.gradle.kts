import dev.silenium.libs.jni.NativePlatform
import dev.silenium.libs.jni.Platform

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
    base
    `maven-publish`
}

group = "dev.silenium.libs.ffmpeg"
version = findProperty("deploy.version") as String? ?: "0.0.0-SNAPSHOT"

val deployNative = (findProperty("deploy.native") as String?)?.toBoolean() ?: true

val withGPL: Boolean = findProperty("ffmpeg.gpl").toString().toBoolean()
val platformExtension = "-gpl".takeIf { withGPL }.orEmpty()
val platformString = findProperty("ffmpeg.platform")?.toString()
val platform = platformString?.let { Platform(it, platformExtension) } ?: NativePlatform.platform(platformExtension)
val compileDir = layout.projectDirectory.dir("cppbuild/${platform}")

val compileNative = if (deployNative) {
    tasks.register<Exec>("compileNative") {
        enabled = deployNative
        commandLine(
            "bash",
            rootProject.layout.projectDirectory.file("cppbuild.sh").asFile.absolutePath,
            "-extension", platform.extension,
            "-platform", platform.osArch,
            "install", "ffmpeg",
        )
        workingDir(rootProject.layout.projectDirectory.asFile)

        inputs.property("platform", platform)
        inputs.files(rootProject.layout.projectDirectory.files("cppbuild.sh"))
        inputs.files(layout.projectDirectory.files("cppbuild.sh"))
        inputs.files(layout.projectDirectory.files("*.patch"))
        inputs.files(layout.projectDirectory.files("*.diff"))
        outputs.dir(compileDir.dir("bin"))
        outputs.dir(compileDir.dir("include"))
        outputs.dir(compileDir.dir("lib"))
        outputs.dir(compileDir.dir("share"))
        outputs.cacheIf { true }
    }
} else null

fun AbstractCopyTask.licenses() {
    from(layout.projectDirectory) {
        include("LICENSE.*", "COPYING.*", "COPYRIGHT.*", "Copyright.*")
    }
}

val nativesJar = if (deployNative) {
    tasks.register<Jar>("nativesJar") {
        dependsOn(compileNative)
        // Required for configuration cache
        val platform =
            platformString?.let { Platform(it, platformExtension) } ?: NativePlatform.platform(platformExtension)

        from(compileDir.dir("lib")) {
            include("*.so")
            include("*.dll")
            include("*.dylib")
            into("natives/$platform/")
        }
        licenses()
    }
} else null

val zipBuild = if (deployNative) {
    tasks.register<Zip>("zipBuild") {
        dependsOn(compileNative)
        from(compileDir) {
            include("bin/**/*")
            include("include/**/*")
            include("lib/**/*")
            include("share/**/*")
        }
        licenses()
    }
} else null

publishing {
    publications {
        if (deployNative) {
            create<MavenPublication>("native${platform.capitalized}") {
                artifact(nativesJar)
                artifact(zipBuild)
                artifactId = "ffmpeg-natives-${platform}"
            }
        }
    }
}
