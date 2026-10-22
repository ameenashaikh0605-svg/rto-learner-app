# WorkManager (pulled in by Google Mobile Ads) creates its Room database by
# reflection. Without these rules R8 removes the generated class and the app
# crashes on launch with "Failed to create an instance of WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.** { *; }
-keep class androidx.startup.** { *; }
