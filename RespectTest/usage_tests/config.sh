respect \
  --config RespectTest/usage_tests/config_test \
  RespectTest/RespectTestProject/RespectTestProject.xcodeproj | \
  grep -q "RespectTest/usage_tests/config_test:1: config test warning"

respect \
  -c RespectTest/usage_tests/config_test \
  RespectTest/RespectTestProject/RespectTestProject.xcodeproj | \
  grep -q "RespectTest/usage_tests/config_test:1: config test warning"

