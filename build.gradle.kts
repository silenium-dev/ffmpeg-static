import org.gradle.internal.extensions.stdlib.capitalized

plugins {
    base
    `maven-publish`
}

group = "dev.silenium.libs"
version = findProperty("deploy.version") as String? ?: "0.0.0-SNAPSHOT"

val platformTxt = layout.buildDirectory.file("platform.txt").apply {
    get().asFile.parentFile.mkdirs()
}
exec {
    commandLine(
        "bash",
        "-c",
        "bash " + layout.projectDirectory.file("detect-platform.sh").asFile.absolutePath + " > " + platformTxt.get().asFile.absolutePath,
    )
    workingDir(layout.projectDirectory.asFile)
}.assertNormalExitValue()
val platform: String = platformTxt.get().asFile.readText().trim()
val platformExtension = findProperty("native.extension") as String? ?: ""
logger.lifecycle("Building for platform: $platform${platformExtension}")

val compileDir = layout.projectDirectory.dir("ffmpeg/cppbuild/${platform}${platformExtension}")

val compileNative by tasks.registering(Exec::class) {
    commandLine(
        "bash",
        layout.projectDirectory.file("cppbuild.sh").asFile.absolutePath,
        "-extension", platformExtension,
        "install",
    )
    workingDir(layout.projectDirectory.asFile)
    environment("PROJECTS" to "ffmpeg")

    inputs.property("platform", platform)
    inputs.files(layout.projectDirectory.files("ffmpeg/*.patch"))
    inputs.files(layout.projectDirectory.files("ffmpeg/*.diff"))
    inputs.files(layout.projectDirectory.files("ffmpeg/cppbuild.sh"))
    outputs.dir(compileDir)
    outputs.cacheIf { true }
}

tasks.build {
    dependsOn(compileNative)
}

val bundleJar by tasks.registering(Jar::class) {
    from(compileNative.get().outputs.files) {
        include("lib/*.so")
        include("lib/*.dll")
        include("lib/*.dylib")
        eachFile {
            path = "natives/$platform/${this.name}"
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

publishing {
    publications {
        create<MavenPublication>("native${platform.split("-").joinToString("") { it.capitalized() }}") {
            artifact(bundleJar)
            artifact(zipBuild)
            artifactId = "ffmpeg-natives-${platform}${platformExtension}"
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
