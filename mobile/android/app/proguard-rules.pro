# Aturan R8 untuk build release (isMinifyEnabled = true).

# MediaPipe Tasks: kode native mencari kelas dan method Java lewat nama aslinya
# (JNI), misalnya TaskRunner dan callback hasil deteksi. Tanpa aturan ini R8
# mengganti nama kelas tersebut dan Hand Landmarker crash saat layar Scan dibuka.
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Konfigurasi task MediaPipe dibaca sebagai protobuf lite, yang mengakses field
# lewat refleksi.
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-dontwarn com.google.protobuf.**

# Dependensi waktu kompilasi yang dirujuk MediaPipe tetapi tidak ada saat runtime.
-dontwarn javax.annotation.**
-dontwarn javax.lang.model.**
-dontwarn com.google.auto.value.**
