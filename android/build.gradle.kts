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

// 라이브러리의 namespace 및 manifest 패키지 충돌 해결
subprojects {
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.BasePlugin) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // AGP 8.0 이상에서 발생하는 namespace 미지정 해결
            if (android.namespace == null) {
                android.namespace = "com.example.the_revelation_flutter.${project.name.replace("-", ".")}"
            }
            
            // AndroidManifest.xml의 package 속성 관련 에러 방지 (AGP 8.0+ 이슈)
            android.sourceSets.getByName("main") {
                manifest.srcFile("src/main/AndroidManifest.xml")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
