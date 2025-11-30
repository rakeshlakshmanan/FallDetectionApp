# Stop any running apps first, then:

flutter clean
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
pod deintegrate
cd ../

flutter pub get
pod install


