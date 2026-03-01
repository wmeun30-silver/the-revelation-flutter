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

// 빌드 경고(Java 8 obsolete)를 해결하기 위한 전역 설정
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        // 자바 컴파일러의 소스/타겟을 17로 맞춤
        sourceCompatibility = "17"
        targetCompatibility = "17"
        // 여전히 경고가 뜨는 경우를 대비해 옵션 경고 무시 추가
        options.compilerArgs.add("-Xlint:-options")
    }
    
    // Kotlin 컴파일러도 17로 맞춤
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
}

subprojects {
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.BasePlugin) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                android.namespace = "com.example.the_revelation_flutter.${project.name.replace("-", ".")}"
            }
            android.sourceSets.getByName("main") {
                manifest.srcFile("src/main/AndroidManifest.xml")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
