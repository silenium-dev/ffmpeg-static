package dev.silenium.libs.ffmpeg

import dev.silenium.libs.jni.NativeLoader
import dev.silenium.libs.jni.NativePlatform

object FFmpeg {
    private val libs = listOf(
        "avcodec",
        "avdevice",
        "avfilter",
        "avformat",
        "avutil",
        "postproc",
        "swresample",
        "swscale",
    )
    private var loadedGPL = false
    private var loadedLGPL = false

    @Synchronized
    fun ensureLoadedGPL(): Result<Unit> {
        if (loadedLGPL) return Result.failure(IllegalStateException("GPL and LGPL libraries are mutually exclusive"))
        if (loadedGPL) return Result.success(Unit)

        libs.forEach {
            NativeLoader.loadLibraryFromClasspath(
                baseName = it,
                platform = NativePlatform.platform("-gpl"),
            )
        }

        loadedGPL = true
        return Result.success(Unit)
    }

    @Synchronized
    fun ensureLoadedLGPL(): Result<Unit> {
        if (loadedGPL) return Result.failure(IllegalStateException("GPL and LGPL libraries are mutually exclusive"))
        if (loadedLGPL) return Result.success(Unit)

        libs.forEach {
            NativeLoader.loadLibraryFromClasspath(
                baseName = it,
                platform = NativePlatform.platform(),
            )
        }

        loadedLGPL = true
        return Result.success(Unit)
    }
}
