# fake Xcode build environment
PROJECT_FILE_PATH=RespectTest/RespectTestProject/RespectTestProject.xcodeproj \
  TARGET_NAME=RespectTestProject \
  CONFIGURATIIN=Release \
  Respect | \
  grep -q "RespectTestProject/main.m:1:4: warning: test warning"
