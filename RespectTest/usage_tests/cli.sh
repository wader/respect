respect \
  RespectTest/RespectTestProject/RespectTestProject.xcodeproj | \
  grep -q "RespectTestProject/main.m:1: test warning"

respect \
  RespectTest/RespectTestProject/RespectTestProject.xcodeproj \
  RespectTestProject | \
  grep -q "RespectTestProject/main.m:1: test warning"

respect \
  RespectTest/RespectTestProject/RespectTestProject.xcodeproj \
  RespectTestProject \
  Release | \
  grep -q "RespectTestProject/main.m:1: test warning"

