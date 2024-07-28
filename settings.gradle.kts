rootProject.name = "ffmpeg-static"

val deployNative = if (extra.has("deploy.native")) {
    extra.get("deploy.native")?.toString()?.toBoolean() ?: true
} else true
if (deployNative) {
    include(":ffmpeg")
}
