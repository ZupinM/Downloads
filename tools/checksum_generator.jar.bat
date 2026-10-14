@rem Lets the firmware generator.bat files call "checksum_generator.jar ..." as a command from a script.
@rem cmd resolves that name to this wrapper via PATHEXT (.BAT) and runs the jar synchronously with java.exe.
@java -jar checksum_generator.jar %*
