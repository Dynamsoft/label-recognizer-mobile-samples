# Dynamsoft Label Recognizer samples for the Android and iOS editions

This repository contains multiple samples that demonstrates how to use the [Dynamsoft Label Recognizer](https://www.dynamsoft.com/label-recognition/overview/) Android and iOS Editions.

## Requirements

### Android
- Operating systems:
  - Supported OS: Android 5 or higher (Android 7 or higher recommended)
  - Supported ABI: armeabi-v7a, arm64-v8a, x86, x86_64
- Environment: Android Studio 3.4+

### iOS
- Operating systems:
  - iOS 9.0 and above.
- Environment: Xcode 7.1 - 11.5 and above.
- Recommended: macOS 10.15.4+, Xcode 11.5+, iOS 11+, CocoaPods 1.11.0

## Samples

### Android

| Sample            | Description |
|---------------|----------------------|
|HelloWorld        | This is a Android sample that illustrates the simplest way to recognize text from an image file with Dynamsoft Label Recognizer SDK. |
|PassportMRZReading       | This Android sample detects the machine readable zone of a passport, recognize the text, and parse the data into surname, given name, nationality, passport number, issuing country or organization, date of birth, sex/gender, and passport expiration date.                 |

### iOS
| Sample            | Description |
|---------------|----------------------|
|HelloWorldObjc         | This is a iOS(ObjectiveC) sample that illustrates the simplest way to recognize text from an image file  with Dynamsoft Label Recognizer SDK.            |
|HelloWorldSwift         | This is a iOS(Swift) sample that illustrates the simplest way to recognize text from an image file  with Dynamsoft Label Recognizer SDK.            |
|PassportMRZReadingObjc        | This iOS(ObjectiveC) sample detects the machine readable zone of a passport, recognize the text, and parse the data into surname, given name, nationality, passport number, issuing country or organization, date of birth, sex/gender, and passport expiration date.                 |
|PassportMRZReadingSwift        | This iOS(Swift) sample detects the machine readable zone of a passport, recognize the text, and parse the data into surname, given name, nationality, passport number, issuing country or organization, date of birth, sex/gender, and passport expiration date.                 |

#### How to build

1. Enter the sample folder, install DLR SDK through `pod` command
    
    ```bash
    pod install
    ```

2. Open the generated file `[SampleName].xcworkspace`

## License

- If you want to use an offline license, please contact [Dynamsoft Support](https://www.dynamsoft.com/company/contact/)
- You can also request a 30-day trial license in the [customer portal](https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=github&package=c_cpp)

## Contact Us

https://www.dynamsoft.com/company/contact/