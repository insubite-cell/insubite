# Keep all TensorFlow Lite classes (GPU, CPU, delegates, etc.)
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Keep GPU delegate options specifically
-keep class org.tensorflow.lite.gpu.** { *; }
