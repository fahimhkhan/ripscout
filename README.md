# ripscout

## Overview  
Welcome to RipScout, the cutting-edge solution for real-time rip current detection and data collection. Utilizing advanced drones equipped with machine learning (ML) technology, RipScout operates independently of an Internet connection, harnessing lightweight ML models optimized for drone controllers' limited computing resources. Our system stands out for its ability to swiftly detect rip currents, hover precisely over the detected area, and collect comprehensive video data from various angles and elevations. 

Designed for ease of use, RipScout empowers even those unfamiliar with rip currents to effectively gather critical data. Field tests confirm that RipScout dramatically enhances data collection speed and accuracy, offering a novel rip current dataset that promises significant advancements in coastal monitoring and safety. With RipScout, we're redefining coastal surveillance and contributing to safer, more informed marine environments.

This repository builds upon the foundational work of [DJI iOS FPV Demo](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-FPVDemo) and [TensorFlow Lite Object Detection](https://github.com/tensorflow/examples/tree/master/lite/examples/object_detection/ios).  

![RipScout](ripscout.png)

### Key Features  
- **DJI Drone Integration**: Utilize DJI drones for autonomous and manual flights.  
- **Real-time Object Detection**: AI-powered detection using TensorFlow Lite.  
- **Swift & iOS Frameworks**: Developed in Swift with a focus on performance and efficiency. 

## Installation & Setup  
### Prerequisites  
- macOS with Xcode installed.  
- CocoaPods for dependency management.  
- DJI SDK development account.  

### Steps  
1. Clone this repository:  
   ```sh
   git clone https://github.com/fahimhkhan/DroneML-Swift.git
   cd DroneML-Swift

2. Install dependencies:
   ```sh
    pod install

3. Open the project using Xcode:
   ```sh
    open DroneML-Swift.xcworkspace
4. Register your app with the DJI Developer Portal and configure the necessary API keys.


### Usage
Launch the app on a connected iOS device.
Connect your DJI drone.
Start object detection using the AI model.

### Disclaimer
The RipScout application software was developed using the DJI Mobile SDK to be compatible with all DJI drones and was tested specifically on the DJI Phantom 4 Pro v2. However, as this software is a prototype, improper use may result in damage or loss of your Drone/UAV.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Acknowledgments
This project is based on:

[DJI iOS FPV Demo](https://github.com/DJI-Mobile-SDK-Tutorials/iOS-FPVDemo)
[TensorFlow Lite Object Detection for iOS](https://github.com/tensorflow/examples/tree/master/lite/examples/object_detection/ios)

### Publication
RipScout: Realtime ML-Assisted Rip Current Detection and Automated Data Collection using UAVs

### Contributing
Contributions are welcome! Feel free contact us at fkhan19@calpoly.edu

### License
This project is licensed under the MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

