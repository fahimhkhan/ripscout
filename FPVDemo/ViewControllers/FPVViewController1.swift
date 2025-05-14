//
//  FPVViewController1.swift
//  DroneMLSwift
//  Rip detection
//
//  Created by Fahim Hasan Khan on 3/31/22.
//  Copyright © 2022 DJI. All rights reserved.
//

//
//  FPVViewController1.swift
//  iOS-FPVDemo-Swift
//

import UIKit
import DJISDK
import DJIWidget


class FPVViewController1: UIViewController,  DJIVideoFeedListener, DJISDKManagerDelegate, DJICameraDelegate, DJIVideoPreviewerFrameControlDelegate{
    
    var dataPassed1: String!
    var isRecording : Bool!
    var isMLrunning : Bool = false
    var isDetected : Bool = false
    
    var sample = 0
    
    var angle = 0
    
    let enableBridgeMode = false
    
    let bridgeAppIP = "10.81.52.50"
    
    var loc1 = CLLocationCoordinate2DMake(36.9623600289201, -122.00799337527907) //Point A - Start
    var loc2 = CLLocationCoordinate2DMake(36.96121985538418, -122.00362673898361) //Point B - Finish
    
    var wpAlt = 80.0 as Float
    
    @IBOutlet var runMLBUtton: UIButton!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var recordTimeLabel: UILabel!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var CirButton: UIButton!
    @IBOutlet weak var cir10: UIButton!
    @IBOutlet weak var cir20: UIButton!
    @IBOutlet weak var cir30: UIButton!
    @IBOutlet var fpvView: PreviewView!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var overlayView: OverlayView!
    @IBOutlet weak var detStatus: UIButton!

    // MARK: Constants
    private let displayFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)
    private let edgeOffset: CGFloat = 2.0
    private let labelOffset: CGFloat = 10.0

    // Holds the results at any time
    private var result: Result?
    // MARK: Controllers that manage functionality
    private var modelDataHandler: ModelDataHandler? =
      ModelDataHandler(modelFileInfo: MobileNetSSDRip.modelInfo, labelsFileInfo: MobileNetSSDRip.labelsInfo)
    
    var flightController: DJIFlightController!
    var timer: Timer?
    var radians: Float = 0.0
    let velocity: Float = 0.1
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard modelDataHandler != nil else {
         fatalError("Failed to load model")
        }
        
        DJISDKManager.registerApp(with: self)
        recordTimeLabel.isHidden = true
        debugLabel.text = dataPassed1
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
//        backgroundImage.image = UIImage(named: "rip.png")
//        backgroundImage.contentMode =  UIView.ContentMode.scaleToFill
//        self.fpvView.insertSubview(backgroundImage, at: 0)
//        self.imageML()
        fpvView.previewLayer.frame = view.bounds
    }
    
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      fpvView.previewLayer.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        if let camera = fetchCamera(), let delegate = camera.delegate, delegate.isEqual(self) {
            camera.delegate = nil
        }
        
        self.resetVideoPreview()
    }
    
    func setupVideoPreviewer() {
        DJIVideoPreviewer.instance().setView(self.fpvView)
        DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        DJIVideoPreviewer.instance().start()
        DJIVideoPreviewer.instance()?.frameControlHandler = self;
    }
    
    func resetVideoPreview() {
        DJIVideoPreviewer.instance().unSetView()
        DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
    }
    
    func fetchCamera() -> DJICamera? {
        guard let product = DJISDKManager.product() else {
            return nil
        }
        if product is DJIAircraft {
            return (product as! DJIAircraft).camera
        }
        return nil
    }
    
    func formatSeconds(seconds: UInt) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return(dateFormatter.string(from: date))
    }
    
    func showAlertViewWithTitle(title: String, withMessage message: String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction.init(title:"OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: DJISDKManagerDelegate Methods
    func productConnected(_ product: DJIBaseProduct?) {
        
        NSLog("Product Connected")
        
        if let camera = fetchCamera() {
            camera.delegate = self
        }
        self.setupVideoPreviewer()
        
        //If this demo is used in China, it's required to login to your DJI account to activate the application. Also you need to use DJI Go app to bind the aircraft to your DJI account. For more details, please check this demo's tutorial.
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: false) { (state, error) in
            if let _ = error {
                NSLog("Login failed: %@" + String(describing: error))
            }
        }
    }
    
    func productDisconnected() {
        NSLog("Product Disconnected")

        if let camera = fetchCamera(), let delegate = camera.delegate, delegate.isEqual(self) {
            camera.delegate = nil
        }
        self.resetVideoPreview()
    }
    
    func appRegisteredWithError(_ error: Error?) {
        var message = "Register App Successed!"
        if let _ = error {
            message = "Register app failed! Please enter your app key and check the network."
        } else {
            if enableBridgeMode {
                DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeAppIP)
            } else {
                DJISDKManager.startConnectionToProduct()
            }
        }
        
        //self.showAlertViewWithTitle(title:"Register App", withMessage: message)
        self.debugLabel.text = message
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        NSLog("Download database : \n%lld/%lld", progress.completedUnitCount, progress.totalUnitCount)
    }

    //Fahim: Camera functions start here
    
    
    // MARK: DJICameraDelegate Method
    func camera(_ camera: DJICamera, didUpdate cameraState: DJICameraSystemState) {
        self.isRecording = cameraState.isRecording
        self.recordTimeLabel.isHidden = !self.isRecording
        
        self.recordTimeLabel.text = formatSeconds(seconds: cameraState.currentVideoRecordingTimeInSeconds)
        
        self.tiltGimbal(ang: self.angle)
        
        if (self.isRecording == true) {
            self.recordButton.setTitle("Rip Detected!! Recording!", for: .normal)
            self.recordButton.setTitleColor(.systemGreen, for: .normal)
        } else {
            self.angle = -90
            self.recordButton.setTitle("No Rip Detected!! Not Recording!", for: .normal)
            self.recordButton.setTitleColor(.systemRed, for: .normal)
        }
        
        
        //Fahim - start recording autometically if Object of interest is detected
        if (self.isDetected == true && self.isRecording == false){
            self.angle = -45
            camera.startRecordVideo(completion: { (error) in
                if let _ = error {
                    NSLog("Start Record Video Error: " + String(describing: error))
                }
            })
            self.isDetected = false
            
            print("WP mission stopped successfully")
            self.debugLabel.text = "WP mission stopped successfully"
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                DJISDKManager.missionControl()?.stopTimeline()
            }
            
            //start hotpoint mission
            
            ///GET THE CURRENT LOCATION FROM DRONE
            ///AND USE FOR HOTPOINT MISSION
            
            ///Hotpoint missions
            
            //var currentLocation = CLLocationCoordinate2D(latitude: 36.98936294389582, longitude: -122.06863243935626)
            let currentLocation = self.currentLocation()
            var debug_string = ""
            self.debugLabel.text = debug_string
            
            let product = DJISDKManager.product()

            if (product?.model) != nil {
                /// This is the array that holds all the timline elements to be executed later in order
                var elements = [DJIMissionControlTimelineElement]()
                
                let dataList = dataPassed1.split(separator: ";")
                
                let hotpointMission1 = DJIHotpointMission()
                hotpointMission1.hotpoint = currentLocation
                hotpointMission1.altitude = Float(dataList[5])!
                hotpointMission1.radius = Float(dataList[6])!
                hotpointMission1.startPoint = .nearest
                hotpointMission1.angularVelocity = 15
                hotpointMission1.heading = .towardHotpoint

                elements.append(hotpointMission1)
                debug_string = debug_string + ",HP1"
                self.debugLabel.text = debug_string
                
//                let hotpointMission2 = DJIHotpointMission()
//                hotpointMission2.hotpoint = currentLocation
//                hotpointMission2.altitude = 15
//                hotpointMission2.radius = 15
//                hotpointMission2.startPoint = .nearest
//                hotpointMission2.angularVelocity = 15
//                hotpointMission2.heading = .towardHotpoint
//
//                elements.append(hotpointMission2)
//                debug_string = debug_string + ",HP2"
//                self.debugLabel.text = debug_string
                
                /// Check if there is any error while appending the timeline mission to the array.
                let error = DJISDKManager.missionControl()?.scheduleElements(elements)
                if error != nil {
                    print("Error detected with the mission")
                    self.debugLabel.text = "HP mission start error"
                } else {
                    /// If there is no error then start the mission
                    print("HP Mission started successfully")
                    self.debugLabel.text = "HP mission started successfully"
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        DJISDKManager.missionControl()?.startTimeline()
                    }
                }
            }
            
        }
        
        
        
        //Fahim - stopping recording autometically after certain time
        if (formatSeconds(seconds: cameraState.currentVideoRecordingTimeInSeconds) == "02:00"){
            camera.stopRecordVideo(completion: { (error) in
                if let _ = error {
                    NSLog("Stop Record Video Error: " + String(describing: error))
                }
            })
            
            ///STOP HOT POINT MISSION
            print("HP mission stopped successfully")
            self.debugLabel.text = "HP mission stopped successfully"
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                DJISDKManager.missionControl()?.stopTimeline()
            }
            
            
            ///CREATE NEW MISSION TO POINT B
            var elements = [DJIMissionControlTimelineElement]()
            let mission = DJIMutableWaypointMission()
            let waypoint2 = DJIWaypoint(coordinate: loc2)
            waypoint2.altitude = wpAlt /// should be of type float
            waypoint2.heading = 0
            waypoint2.actionRepeatTimes = 1
            waypoint2.actionTimeoutInSeconds = 60
            waypoint2.turnMode = .clockwise
            waypoint2.gimbalPitch = 0
                         
            mission.add(waypoint2)
            elements.append(mission) // task number 2
              
               
          /// Check if there is any error while appending the timeline mission to the array.
          let error = DJISDKManager.missionControl()?.scheduleElements(elements)
          if error != nil {
            print("Error detected with the mission")
            self.debugLabel.text = "WP mission resumed failed"
          } else {
            /// If there is no error then start the mission
            print("WP mission resumed successfully")
            self.debugLabel.text = "WP mission resumed successfully"
            DispatchQueue.main.asyncAfter(deadline: .now()) {
              DJISDKManager.missionControl()?.startTimeline()
            }
          }

        }
        
        //Update UISegmented Control's State
        
        //Fahim - setting video record mode as default
        camera.setMode(DJICameraMode.recordVideo,  withCompletion: { (error) in
            if let _ = error {
                NSLog("Set RecordVideo Mode Error: " + String(describing: error))
            }
        })
        
        //let img = self.fpvView.asImage()
        
        //let renderer = UIGraphicsImageRenderer(size: fpvView.bounds.size)
        //let img = renderer.image { ctx in fpvView.drawHierarchy(in: fpvView.bounds, afterScreenUpdates: true) }
        //self.imageView.image = img
        
        if (self.isMLrunning == true){
            //self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true, block: { _ in self.imageML()})
            if (sample % 10 == 0){
                self.imageML()
            }
            self.runMLBUtton.setTitle("Stop ML", for: .normal)
            self.runMLBUtton.setTitleColor(.systemGreen, for: .normal)
            //self.isMLrunning = false
        } else{
            self.runMLBUtton.setTitle("Run ML", for: .normal)
            self.runMLBUtton.setTitleColor(.systemRed, for: .normal)
        }
        sample = sample + 1
        //self.imageML()

    }
    
    // MARK: DJIVideoFeedListener Method
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData rawData: Data) {
        let videoData = rawData as NSData
        let videoBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: videoData.length)
        videoData.getBytes(videoBuffer, length: videoData.length)
        DJIVideoPreviewer.instance().push(videoBuffer, length: Int32(videoData.length))
    }
    
    func imageML(){
        let renderer = UIGraphicsImageRenderer(size: fpvView.bounds.size)
        let img = renderer.image { ctx in fpvView.drawHierarchy(in: fpvView.bounds, afterScreenUpdates: true) }

        let pixelbuffer: CVPixelBuffer? = buffer(from: img)
        
        self.runModel(onPixelBuffer: pixelbuffer!)
    }
    
    func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
    
    /** This method runs the live camera pixelBuffer through tensorFlow to get the result.
     */
    @objc  func runModel(onPixelBuffer pixelBuffer: CVPixelBuffer) {

      // Run the live camera pixelBuffer through tensorFlow to get the result

      result = self.modelDataHandler?.runModel(onFrame: pixelBuffer)

      guard let displayResult = result else {
        return
      }

      let width = CVPixelBufferGetWidth(pixelBuffer)
      let height = CVPixelBufferGetHeight(pixelBuffer)

      DispatchQueue.main.async {

        //Draws the bounding boxes and displays class names and confidence scores.
        self.drawAfterPerformingCalculations(onInferences: displayResult.inferences, withImageSize: CGSize(width: CGFloat(width), height: CGFloat(height)))
      }
    }
    
    /**
     This method takes the results, translates the bounding box rects to the current view, draws the bounding boxes, classNames and confidence scores of inferences.
     */
    func drawAfterPerformingCalculations(onInferences inferences: [Inference], withImageSize imageSize:CGSize) {

      self.overlayView.objectOverlays = []
      self.overlayView.setNeedsDisplay()
      //guard !inferences.isEmpty else {
        //return
      //}

      var objectOverlays: [ObjectOverlay] = []
      //let objectOverlayTest = ObjectOverlay(name: "Test Rip", borderRect: CGRect(x: 100.0, y: 100.0, width: 200.0, height: 200.0), nameStringSize: CGSize(width: 90.0, height: 15.0), color: UIColor.red, font: self.displayFont)
      //objectOverlays.append(objectOverlayTest)
      
    
      for inference in inferences {

        // Translates bounding box rect to current view.
        var convertedRect = inference.rect.applying(CGAffineTransform(scaleX: self.overlayView.bounds.size.width / imageSize.width, y: self.overlayView.bounds.size.height / imageSize.height))

        if convertedRect.origin.x < 0 {
          convertedRect.origin.x = self.edgeOffset
        }

        if convertedRect.origin.y < 0 {
          convertedRect.origin.y = self.edgeOffset
        }

        if convertedRect.maxY > self.overlayView.bounds.maxY {
          convertedRect.size.height = self.overlayView.bounds.maxY - convertedRect.origin.y - self.edgeOffset
        }

        if convertedRect.maxX > self.overlayView.bounds.maxX {
          convertedRect.size.width = self.overlayView.bounds.maxX - convertedRect.origin.x - self.edgeOffset
        }

        let confidenceValue = Int(inference.confidence * 100.0)
        let string = "\(inference.className)  (\(confidenceValue)%)"

        let size = string.size(usingFont: self.displayFont)

        let objectOverlay = ObjectOverlay(name: string, borderRect: convertedRect, nameStringSize: size, color: inference.displayColor, font: self.displayFont)

        objectOverlays.append(objectOverlay)
        self.isDetected = true
          //}
      }

      // Hands off drawing to the OverlayView
      self.draw(objectOverlays: objectOverlays)

    }

    /** Calls methods to update overlay view with detected bounding boxes and class names.
     */
    func draw(objectOverlays: [ObjectOverlay]) {
      self.overlayView.objectOverlays = objectOverlays
      self.overlayView.setNeedsDisplay()
    }
    
    func tiltGimbal(ang: Int) {
        let gimbal = DJISDKManager.product()?.gimbal
        let rotation = DJIGimbalRotation(pitchValue: ang as NSNumber, rollValue: 0, yawValue: 0, time: 1, mode: .absoluteAngle, ignore: true)
        gimbal?.rotate(with: rotation, completion: { (error) in
            if error != nil {
                print("Error rotating gimbal")
                }
            })
        }
 
    @IBAction func detAction(_ sender: UIButton) {
            if (self.isDetected == false) {
                self.isDetected = true
                self.detStatus.setTitle("Det True!", for: .normal)
            }
            else {
                self.isDetected = false
                self.detStatus.setTitle("Det False!", for: .normal)
            }
    }
    
    
    @IBAction func recordAction(_ sender: UIButton) {
        guard let camera = fetchCamera() else {
            return
        }
        
        if (self.isRecording) {
            camera.stopRecordVideo(completion: { (error) in
                if let _ = error {
                    NSLog("Stop Record Video Error: " + String(describing: error))
                }
            })
        } else {
            camera.startRecordVideo(completion: { (error) in
                if let _ = error {
                    NSLog("Start Record Video Error: " + String(describing: error))
                }
            })
        }
    }
    
    
    @IBAction func runMLAction(_ sender: UIButton) {
        if (self.isMLrunning == true){
            isMLrunning = false
        }
        else{
            isMLrunning = true
        }
    }
    
    
    @IBAction func actionOrbit(_ sender: Any) {
        self.circleMission()
    }
    
    /// Set up the drone misison and strart its timeline
    func circleMission() {
        /// Check if the drone is connected
        let product = DJISDKManager.product()
        
        //var alti = (flightControllerState.aircraftLocation?.altitude) ?? 0
        
        var debug_string = ""
        self.debugLabel.text = debug_string

        if (product?.model) != nil {
            /// This is the array that holds all the timline elements to be executed later in order
            var elements = [DJIMissionControlTimelineElement]()
            
            let takeOff = DJITakeOffAction()
            elements.append(takeOff) // task number 1
            
            var debug_string = debug_string + ",Takeoff"
            self.debugLabel.text = debug_string
            
            /// Set up and start a new waypoint mission
            var mission: DJIWaypointMission?
            guard let result = self.waypointSetup() else {return}
            mission = result
            elements.append(mission!) // task number 2
            debug_string = debug_string + ",WPs"
            self.debugLabel.text = debug_string
            
            /// This is the go home and landing action in which the drone goes back to its starting point when the first time started the mission
            let goHomeLandingAction = DJIGoHomeAction()
            elements.append(goHomeLandingAction) // task number 3
            ///
            debug_string = debug_string + ",retHome"
            self.debugLabel.text = debug_string
            
            /// Check if there is any error while appending the timeline mission to the array.
            let error = DJISDKManager.missionControl()?.scheduleElements(elements)
            if error != nil {
                print("Error detected with the mission")
            } else {
                /// If there is no error then start the mission
                print("Mission started successfully")
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    DJISDKManager.missionControl()?.startTimeline()
                }
            }
        }
    }
    
    @IBAction func cir30Action(_ sender: Any) {
        self.flyCircle(radius: 30.0)
    }
    
    
    @IBAction func showLocAction(_ sender: UIButton) {
        self.flyCircle(radius: 20.0)
    }
    
    @IBAction func cir10Action(_ sender: UIButton) {
        self.flyCircle(radius: 10.0)
    }
    
    
    func flyCircle(radius: Float){
        self.angle = -45
        let coordinate = self.currentLocation()
        let coordinateString = "\(coordinate.latitude), \(coordinate.longitude)"
        self.debugLabel.text = coordinateString
        
        /// Check if the drone is connected
        let product = DJISDKManager.product()
        
        //var alti = (flightControllerState.aircraftLocation?.altitude) ?? 0
        
        var debug_string = ""
        self.debugLabel.text = debug_string

        if (product?.model) != nil {
            /// This is the array that holds all the timline elements to be executed later in order
            var elements = [DJIMissionControlTimelineElement]()
            
            let hotpointMission = DJIHotpointMission()
            hotpointMission.hotpoint = coordinate
            hotpointMission.altitude = radius
            hotpointMission.radius = radius
            hotpointMission.startPoint = .nearest
            hotpointMission.angularVelocity = 15
            hotpointMission.heading = .towardHotpoint

            elements.append(hotpointMission)  /// task number 2
            debug_string = debug_string + ",HP"
            self.debugLabel.text = debug_string
            
            /// Check if there is any error while appending the timeline mission to the array.
            let error = DJISDKManager.missionControl()?.scheduleElements(elements)
            if error != nil {
                print("Error detected with the mission")
            } else {
                /// If there is no error then start the mission
                print("Mission started successfully")
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    DJISDKManager.missionControl()?.startTimeline()
                }
            }
        }
    }
    
    func currentLocation() -> CLLocationCoordinate2D {
        /// Keep listening to the drone location included in latitude and longitude
        guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
            return CLLocationCoordinate2DMake(0, 0)
        }
        guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
            return CLLocationCoordinate2DMake(0, 0)
        }
        let droneLocation = droneLocationValue.value as! CLLocation
        let droneCoordinates = droneLocation.coordinate
        /// Check if the returned coordinate value is valid or not
        if !CLLocationCoordinate2DIsValid(droneCoordinates) {
            return CLLocationCoordinate2DMake(0, 0)
        }
        return droneCoordinates
    }
    
    
    func waypointSetup() -> DJIWaypointMission? {
            /// Define a new object class for the waypoint mission
            let mission = DJIMutableWaypointMission()
            
            var debug_string = "waypointMission"
            self.debugLabel.text = debug_string
            
            mission.maxFlightSpeed = 15
            mission.autoFlightSpeed = 8
            mission.finishedAction = .noAction
            mission.headingMode = .usingInitialDirection
            mission.flightPathMode = .normal
            mission.rotateGimbalPitch = false /// Change this to True if you want the camera gimbal pitch to move between waypoints
            mission.exitMissionOnRCSignalLost = true
            mission.gotoFirstWaypointMode = .safely
            mission.repeatTimes = 1
            
            debug_string = debug_string + ",ini"
            self.debugLabel.text = debug_string
        
            let dataList = dataPassed1.split(separator: ";")
        
            var coord1 = dataList[1].split(separator: ",")
            loc1 = CLLocationCoordinate2DMake(Double(coord1[0])!, Double(coord1[1])!)
        
            var coord2 = dataList[2].split(separator: ",")
            loc1 = CLLocationCoordinate2DMake(Double(coord2[0])!, Double(coord2[1])!)
        
            let waypoint1 = DJIWaypoint(coordinate: loc1)
            
            // waypoint1.altitude = wpAlt /// The altitude which the drone flies to as the first point and should be of type float
            waypoint1.altitude = Float(dataList[3])!
            waypoint1.heading = 0 /// This is between [-180, 180] degrees, where the drone moves when reaching a waypoint. 0 means don't change the drone's heading
            waypoint1.actionRepeatTimes = 1 /// Repeat this mission just for one time
            waypoint1.actionTimeoutInSeconds = 60
            // waypoint1.cornerRadiusInMeters = 5
            waypoint1.turnMode = .clockwise /// When the drones changing its heading. It moves clockwise
            waypoint1.gimbalPitch = 0
        
            debug_string = debug_string + ",w1"
            self.debugLabel.text = debug_string
            
            
            let waypoint2 = DJIWaypoint(coordinate: loc2)
            // waypoint2.altitude = wpAlt /// should be of type float
            waypoint2.altitude = Float(dataList[4])!
            waypoint2.heading = 0
            waypoint2.actionRepeatTimes = 1
            waypoint2.actionTimeoutInSeconds = 60
            waypoint2.turnMode = .clockwise
            waypoint2.gimbalPitch = 0
            
            debug_string = debug_string + ",w2"
            self.debugLabel.text = debug_string
            
            mission.add(waypoint1)
            mission.add(waypoint2)
            
            debug_string = debug_string + ",ret"
            self.debugLabel.text = debug_string
            return DJIWaypointMission(mission: mission)
        }
    
    // MARK: DJIVideoPreviewerFrameControlDelegate Method
    func parseDecodingAssistInfo(withBuffer buffer: UnsafeMutablePointer<UInt8>!, length: Int32, assistInfo: UnsafeMutablePointer<DJIDecodingAssistInfo>!) -> Bool {
        return DJISDKManager.videoFeeder()?.primaryVideoFeed.parseDecodingAssistInfo(withBuffer: buffer, length: length, assistInfo: assistInfo) ?? false
    }
    
    func isNeedFitFrameWidth() -> Bool {
        let displayName = fetchCamera()?.displayName
        if displayName == DJICameraDisplayNameMavic2ZoomCamera ||
            displayName == DJICameraDisplayNameMavic2ProCamera {
            return true
        }
        return false
    }
    
    func syncDecoderStatus(_ isNormal: Bool) {
        DJISDKManager.videoFeeder()?.primaryVideoFeed.syncDecoderStatus(isNormal)
    }
    
    func decodingDidSucceed(withTimestamp timestamp: UInt32) {
        DJISDKManager.videoFeeder()?.primaryVideoFeed.decodingDidSucceed(withTimestamp: UInt(timestamp))
    }
    
    func decodingDidFail() {
        DJISDKManager.videoFeeder()?.primaryVideoFeed.decodingDidFail()
    }
    
}


extension UIImage {
    
    func resizeImageTo1(size: CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

