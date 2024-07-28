# ffmpeg-static

Statically linked ffmpeg builds

## Artifacts

Artifacts can be found here: https://reposilite.silenium.dev/#/releases/dev/silenium/libs/ffmpeg

- LGPL and GPL variants of ffmpeg.
- Kotlin wrapper to load the dynamic ffmpeg libraries into JNI
- zipped builds that contain all output files produced by the build, can be used to link your own code against
- platform naming scheme and detection is provided by https://github.com/silenium-dev/jni-utils

## Use in a Gradle project

```kotlin
repositories {
    maven("https://reposilite.silenium.dev/releases") {
        name = "silenium-releases"
    }
}

dependencies {
    implementation("dev.silenium.libs.ffmpeg:ffmpeg-natives:7.0+0.2.0")
    implementation("dev.silenium.libs.ffmpeg:ffmpeg-natives-linux-x86_64:7.0+0.2.0") // replace "linux-x86_64" with your platform
}
```

## Platforms

### Supported

- Linux arm64/aarch64
- Linux armv7/armhf
- Linux x86_64/amd64
- Linux x86/i686
- Linux ppc64le

### Planned

- Android arm64/aarch64
- Android armv7/armhf
- Android x86_64/amd64
- Android x86/i686
- Windows x86_64/amd64
- Windows x86/i686

### Not planned / low priority

- macOS x86_64/amd64
- macOS arm64/aarch64
- macOS x86/i686
