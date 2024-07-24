import org.gradle.internal.extensions.stdlib.capitalized
import kotlin.io.path.createDirectories

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

val compileNative by tasks.registering(Exec::class) {
    commandLine(
        "bash",
        layout.projectDirectory.file("cppbuild.sh").asFile.absolutePath,
        "-extension", findProperty("native.extension") as String? ?: "",
        "install",
    )
    workingDir(layout.projectDirectory.asFile)
    environment("PROJECTS" to "ffmpeg")

    project.logger.lifecycle("Building for platform: $platform")
    outputs.files(layout.projectDirectory.dir("ffmpeg/cppbuild/${platform}/lib").asFileTree.filter {
        it.name.contains(".so") || it.name.contains(".dll") || it.name.contains(".dylib")
    })
    inputs.property("platform", platform)
    inputs.files(layout.projectDirectory.files("ffmpeg/*.patch"))
    inputs.files(layout.projectDirectory.files("ffmpeg/*.diff"))
    inputs.files(layout.projectDirectory.files("ffmpeg/cppbuild.sh"))
    outputs.dir(layout.projectDirectory.dir("ffmpeg/cppbuild/${platform}/bin"))
    outputs.dir(layout.projectDirectory.dir("ffmpeg/cppbuild/${platform}/include"))
    outputs.dir(layout.projectDirectory.dir("ffmpeg/cppbuild/${platform}/lib"))
    outputs.dir(layout.projectDirectory.dir("ffmpeg/cppbuild/${platform}/share"))
    outputs.cacheIf { true }
}

tasks.build {
    dependsOn(compileNative)
}

val bundleSharedLibs by tasks.registering(Jar::class) {
    from(compileNative.map { it.outputs.files })
    into("natives/")
    rename {
        val base = it.substringBefore(".")
        val ext = it.substringAfter(".")
        "$base-$platform.$ext"
    }
}

publishing {
    publications {
        create<MavenPublication>("native${platform.split("-").joinToString("") { it.capitalized() }}") {
            artifact(bundleSharedLibs)
            artifactId = "ffmpeg-${platform}"
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
