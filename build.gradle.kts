import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinVersion

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

val deployKotlin = (findProperty("deploy.kotlin") as String?)?.toBoolean() ?: true

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

tasks.jar {
    from(layout.projectDirectory) {
        include("LICENSE", "THIRDPARTY_LICENSES")
    }
}

allprojects {
    apply<MavenPublishPlugin>()

    publishing {
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
}

publishing {
    publications {
        if (deployKotlin) {
            create<MavenPublication>("kotlin") {
                from(components["java"])
                artifactId = "ffmpeg-natives"
            }
        }
    }
}
