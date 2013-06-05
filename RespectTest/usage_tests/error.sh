respect --not_existing 2>&1 | grep -q "unrecognized option"
respect not_existing 2>&1 | grep -q "Failed"
respect RespectTest/RespectTestProject/RespectTestProject.xcodeproj non_existing 2>&1 | grep -q "No native target named"
respect RespectTest/RespectTestProject/RespectTestProject.xcodeproj RespectTestProject non_existing 2>&1 | grep -q "No configuration named"
