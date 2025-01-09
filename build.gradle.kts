import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinVersion

plugins {
    alias(libs.plugins.kotlin)
    `maven-publish`
}

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
        languageVersion = KotlinVersion.KOTLIN_1_8
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
    apply<BasePlugin>()

    group = "dev.silenium.libs.ffmpeg"
    version = findProperty("deploy.version") as String? ?: "0.0.0-SNAPSHOT"

    publishing {
        repositories {
            val url = System.getenv("MAVEN_REPO_URL") ?: return@repositories
            maven(url) {
                name = "reposilite"
                credentials {
                    username = System.getenv("MAVEN_REPO_USERNAME") ?: ""
                    password = System.getenv("MAVEN_REPO_PASSWORD") ?: ""
                }
                authentication {
                    create<BasicAuthentication>("basic")
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
