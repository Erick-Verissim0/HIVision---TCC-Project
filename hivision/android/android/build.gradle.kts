val localPropsFile = rootProject.file("local.properties")
val localProps = java.util.Properties()
if (localPropsFile.exists()) {
    localPropsFile.inputStream().use { localProps.load(it) }
}
if (localProps.getProperty("sdk.dir").isNullOrBlank()) {
    val sdkCandidates = listOfNotNull(
        System.getenv("ANDROID_HOME"),
        System.getenv("ANDROID_SDK_ROOT"),
        "${System.getProperty("user.home")}/Library/Android/sdk",
        "${System.getProperty("user.home")}/Android/Sdk",
    )
    val detectedSdk = sdkCandidates.firstOrNull { path -> file(path).exists() }
    if (detectedSdk != null) {
        localProps.setProperty("sdk.dir", detectedSdk)
        localPropsFile.outputStream().use { localProps.store(it, null) }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
