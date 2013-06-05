respect \
  --d \
  RespectTest/RespectTestProject/RespectTestProject.xcodeproj | \
  grep -q "Interpreted config for"

respect \
  --dumpconfig \
  RespectTest/RespectTestProject/RespectTestProject.xcodeproj | \
  grep -q "Interpreted config for"

