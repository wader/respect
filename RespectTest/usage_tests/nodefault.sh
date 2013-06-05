# look for "Unused resources", Info.ploist etc is not added without defaults
respect \
  --nodefault \
  RespectTest/RespectTestProject/RespectTestProject.xcodeproj | \
  grep -q "Unused resources"

respect \
  -n \
  RespectTest/RespectTestProject/RespectTestProject.xcodeproj | \
  grep -q "Unused resources"

