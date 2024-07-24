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

val compileDir = layout.projectDirectory.dir("ffmpeg/cppbuild/${platform}")

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
    inputs.property("platform", platform)
    inputs.files(layout.projectDirectory.files("ffmpeg/*.patch"))
    inputs.files(layout.projectDirectory.files("ffmpeg/*.diff"))
    inputs.files(layout.projectDirectory.files("ffmpeg/cppbuild.sh"))
    outputs.dir(layout.projectDirectory.dir("ffmpeg/cppbuild/${platform}"))
    outputs.cacheIf { true }
}

tasks.build {
    dependsOn(compileNative)
}

val bundleJar by tasks.registering(Jar::class) {
    from(compileNative.get().outputs.files) {
        include("*.so")
        include("*.dll")
        include("*.dylib")
        into("natives/$platform/")
    }
}

val zipBuild by tasks.registering(Zip::class) {
    doFirst {
        val dir = compileDir.asFile
        dir.list()?.forEach(::println)
    }
    from(compileNative.get().outputs.files) {
        include("bin/**")
        include("include/**")
        include("lib/**")
        include("share/**")
    }
}

publishing {
    publications {
        create<MavenPublication>("native${platform.split("-").joinToString("") { it.capitalized() }}") {
            artifact(bundleJar)
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
