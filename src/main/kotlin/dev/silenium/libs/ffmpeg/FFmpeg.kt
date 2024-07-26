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
    private var loaded = false

    @Synchronized
    fun ensureLoaded(withGPL: Boolean = false) {
        if (loaded) return

        libs.forEach {
            NativeLoader.loadLibraryFromClasspath(
                baseName = it,
                platform = NativePlatform.platform("-gpl".takeIf { withGPL }.orEmpty()),
            )
        }

        loaded = true
    }
}
