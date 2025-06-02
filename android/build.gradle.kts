allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // 针对 firebase_installations 插件缺少 namespace 的兼容处理
    if (name == "firebase_installations") {
        plugins.withId("com.android.library") {
            // 原 configure 块已移除
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")

    // 修复 firebase_installations 缺少 namespace 的问题
    if (name == "firebase_installations") {
        afterEvaluate {
            // 尝试获取 LibraryExtension 并设置 namespace
            val libExt = extensions.findByName("android") as? com.android.build.api.dsl.LibraryExtension
            libExt?.namespace = "io.flutter.plugins.firebase.installations"

            // 移除 AndroidManifest 中的 package 属性，避免 AGP 8 报错
            tasks.matching { it.name.startsWith("process") && it.name.endsWith("Manifest") }.configureEach {
                doFirst {
                    val manifest = file("${project.projectDir}/src/main/AndroidManifest.xml")
                    if (manifest.exists()) {
                        val text = manifest.readText(Charsets.UTF_8)
                        val newText = text.replace(Regex("package=\"[^\"]+\""), "")
                        if (newText != text) {
                            manifest.writeText(newText, Charsets.UTF_8)
                            println("[fix] removed package attr from firebase_installations manifest")
                        }
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
