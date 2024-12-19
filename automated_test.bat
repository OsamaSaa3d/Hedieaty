@echo off

REM Start screen recording in the background
echo Starting screen recording...
start /B adb shell screenrecord /sdcard/test_screen.mp4

REM Run the integration tests
echo Running integration tests...
flutter drive --driver=test_driver/integration_test_driver.dart --target=test/integration_tests/full_test.dart

REM Stop screen recording after tests are done
echo Stopping screen recording...
adb shell pkill -f screenrecord

REM Pull the video file and logs
echo Pulling screen recording from device...
adb pull /sdcard/test_screen.mp4 .\test_screen.mp4

echo Pulling device logs...
adb logcat -d > .\test_logs.txt

REM Calculate test coverage
echo calculating coverage
flutter test --coverage

echo Process completed!
pause
