import SwiftUI
import GameController
import AppKit // Required for NSColor and related components on macOS

// This class acts as the data model for the controller's state.
// The @Published properties automatically notify the SwiftUI view of any changes.
class DualSenseState: ObservableObject {
    @Published var isCrossPressed: Bool = false
    @Published var isCirclePressed: Bool = false
    @Published var isSquarePressed: Bool = false
    @Published var isTrianglePressed: Bool = false
    
    @Published var isDPadUp: Bool = false
    @Published var isDPadDown: Bool = false
    @Published var isDPadLeft: Bool = false
    @Published var isDPadRight: Bool = false
    
    @Published var leftStickX: Float = 0.0
    @Published var leftStickY: Float = 0.0
    @Published var rightStickX: Float = 0.0
    @Published var rightStickY: Float = 0.0
    
    // New properties for Triggers, Bumpers, and other buttons
    @Published var isLeftBumperPressed: Bool = false
    @Published var isRightBumperPressed: Bool = false
    @Published var leftTriggerValue: Float = 0.0
    @Published var rightTriggerValue: Float = 0.0
    @Published var isLeftStickPressed: Bool = false
    @Published var isRightStickPressed: Bool = false
    @Published var isMenuPressed: Bool = false
    @Published var isOptionsPressed: Bool = false
    @Published var isTouchpadPressed: Bool = false
    @Published var isPlayStationPressed: Bool = false
    
    // New properties for battery status
    @Published var batteryLevel: Float? = nil
    @Published var batteryState: GCDeviceBattery.State = .unknown
}

// The main view of your app.
struct ContentView: View {
    // @StateObject creates a persistent instance of our data model.
    @StateObject private var dualSenseState = DualSenseState()
    
    // The currently connected controller instance.
    @State private var dualSense: GCDualSenseGamepad?
    
    // The currently connected general controller to access the light property.
    @State private var connectedController: GCController?
    
    // The color chosen by the user for the light bar.
    @State private var selectedLightBarColor: Color = .blue
    
    // State variable for the player index slider.
    @State private var playerIndexSliderValue: Float = 1.0

    let stickSize: CGFloat = 40
    let stickBounds: CGFloat = 60
    
    let buttonColor: Color = .gray
    let pressedColor: Color = .blue

    var body: some View {
        VStack(spacing: 10) { // Reduced spacing to make it more compact
            Text("DualSense Controller Tester")
                .font(.title)
                .padding(.bottom, 10) // Reduced padding
                .onAppear {
                    setupControllerObservers()
                    setupBatteryObserver()
                }
            
            // The ColorPicker for the light bar has been added back.
            ColorPicker("Light Bar Color", selection: $selectedLightBarColor)
                .padding()
                // Use a listener to update the light bar in real time.
                .onChange(of: selectedLightBarColor) { oldColor, newColor in
                    updateLightBarColor(to: newColor)
                }

            // Slider to control the Player Index
            VStack {
                Text("Player Index: \(Int(playerIndexSliderValue))")
                Slider(value: $playerIndexSliderValue, in: 0...4, step: 1.0)
                    .padding(.horizontal)
                    .onChange(of: playerIndexSliderValue) { oldIndex, newIndex in
                        updatePlayerIndex(to: Int(newIndex))
                    }
            }
            .padding(.top, 10) // Reduced padding
            
            ZStack {
                // The main controller body shape
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color(white: 0.15))
                    .frame(width: 350, height: 200)
                
                // Overlay for the buttons and sticks
                VStack(spacing: 5) { // Reduced spacing to make it more compact
                    // Top Row: Triggers & Bumpers
                    HStack(spacing: 60) { // Reduced spacing for triggers/bumpers
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(buttonColor, lineWidth: 2)
                                .frame(width: 60, height: 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(pressedColor)
                                        .opacity(Double(dualSenseState.leftTriggerValue))
                                )
                            Text("L2")
                        }
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(buttonColor, lineWidth: 2)
                                .frame(width: 60, height: 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(pressedColor)
                                        .opacity(Double(dualSenseState.rightTriggerValue))
                                )
                            Text("R2")
                        }
                    }
                    .padding(.top, -30)

                    HStack(spacing: 100) { // Spacing between the trigger and bumper rows
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(dualSenseState.isLeftBumperPressed ? pressedColor : buttonColor)
                                .frame(width: 60, height: 20)
                            Text("L1")
                        }
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(dualSenseState.isRightBumperPressed ? pressedColor : buttonColor)
                                .frame(width: 60, height: 20)
                            Text("R1")
                        }
                    }
                    .padding(.top, -30) // Adjusted padding

                    HStack(spacing: 40) { // Reduced spacing for the main layout
                        // Left Side - D-Pad & Left Stick
                        VStack(spacing: 10) {
                            // D-Pad
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(dualSenseState.isDPadUp ? pressedColor : buttonColor)
                                    .frame(width: 30, height: 30)
                                HStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(dualSenseState.isDPadLeft ? pressedColor : buttonColor)
                                        .frame(width: 30, height: 30)
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(.clear)
                                        .frame(width: 30, height: 30)
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(dualSenseState.isDPadRight ? pressedColor : buttonColor)
                                        .frame(width: 30, height: 30)
                                }
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(dualSenseState.isDPadDown ? pressedColor : buttonColor)
                                    .frame(width: 30, height: 30)
                            }
                            // Left Stick
                            ZStack {
                                Circle()
                                    .stroke(dualSenseState.isLeftStickPressed ? pressedColor : buttonColor, lineWidth: 2)
                                    .frame(width: stickBounds, height: stickBounds)
                                Circle()
                                    .fill(pressedColor)
                                    .frame(width: stickSize, height: stickSize)
                                    .offset(x: CGFloat(dualSenseState.leftStickX) * (stickBounds - stickSize) / 2,
                                            y: -CGFloat(dualSenseState.leftStickY) * (stickBounds - stickSize) / 2)
                                    .animation(.spring(), value: dualSenseState.leftStickX)
                                    .animation(.spring(), value: dualSenseState.leftStickY)
                            }
                        }
                        
                        // Right Side - Face Buttons & Right Stick
                        VStack(spacing: 10) {
                            // Face Buttons
                            VStack(spacing: 10) {
                                Circle()
                                    .fill(dualSenseState.isTrianglePressed ? pressedColor : buttonColor)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Path { path in
                                            path.move(to: CGPoint(x: 20, y: 10))
                                            path.addLine(to: CGPoint(x: 35, y: 30))
                                            path.addLine(to: CGPoint(x: 5, y: 30))
                                            path.closeSubpath()
                                        }
                                        .stroke(Color.white, lineWidth: 2)
                                    )
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(dualSenseState.isSquarePressed ? pressedColor : buttonColor)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .frame(width: 20, height: 20)
                                        )
                                    Circle()
                                        .fill(dualSenseState.isCrossPressed ? pressedColor : buttonColor)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Path { path in
                                                path.move(to: CGPoint(x: 10, y: 10))
                                                path.addLine(to: CGPoint(x: 30, y: 30))
                                                path.move(to: CGPoint(x: 30, y: 10))
                                                path.addLine(to: CGPoint(x: 10, y: 30))
                                            }
                                            .stroke(Color.white, lineWidth: 2)
                                        )
                                }
                                Circle()
                                    .fill(dualSenseState.isCirclePressed ? pressedColor : buttonColor)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 20, height: 20)
                                    )
                            }
                            // Right Stick
                            ZStack {
                                Circle()
                                    .stroke(dualSenseState.isRightStickPressed ? pressedColor : buttonColor, lineWidth: 2)
                                    .frame(width: stickBounds, height: stickBounds)
                                Circle()
                                    .fill(pressedColor)
                                    .frame(width: stickSize, height: stickSize)
                                    .offset(x: CGFloat(dualSenseState.rightStickX) * (stickBounds - stickSize) / 2,
                                            y: -CGFloat(dualSenseState.rightStickY) * (stickBounds - stickSize) / 2)
                                    .animation(.spring(), value: dualSenseState.rightStickX)
                                    .animation(.spring(), value: dualSenseState.rightStickY)
                            }
                        }
                    }
                }
            }
            // Other buttons and trigger values
            HStack(spacing: 20) { // Reduced spacing
                VStack {
                    Text("Share")
                    Circle()
                        .fill(dualSenseState.isOptionsPressed ? pressedColor : buttonColor)
                        .frame(width: 30, height: 30)
                }
                VStack {
                    Text("Touchpad")
                    RoundedRectangle(cornerRadius: 10)
                        .fill(dualSenseState.isTouchpadPressed ? pressedColor : buttonColor)
                        .frame(width: 80, height: 50)
                        .overlay(alignment: .center) {
                            if dualSenseState.isTouchpadPressed {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 10, height: 10)
                                    .animation(.spring(), value: dualSenseState.isTouchpadPressed)
                            }
                        }
                }
                VStack {
                    Text("Menu")
                    Circle()
                        .fill(dualSenseState.isMenuPressed ? pressedColor : buttonColor)
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.top, 10) // Reduced padding
            
            // New row for PlayStation button and Battery Status
            HStack(spacing: 20) { // Reduced spacing
                VStack {
                    Text("PlayStation")
                    Circle()
                        .fill(dualSenseState.isPlayStationPressed ? pressedColor : buttonColor)
                        .frame(width: 30, height: 30)
                }
                
                // Display battery information
                VStack(alignment: .leading) {
                    Text("Battery Status")
                        .font(.headline)
                    // Display the battery level as a percentage.
                    Text(dualSenseState.batteryLevel.map { "Level: \(Int($0 * 100))%" } ?? "Level: N/A")
                    // Display the battery charging state.
                    Text("State: \(getBatteryStateString(state: dualSenseState.batteryState))")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
            }
            .padding(.top, 10) // Reduced padding
        }
        .padding()
    }
    
    /// Converts a SwiftUI.Color to its RGBA components.
    private func getRGBAComponents(from color: Color) -> (red: Float, green: Float, blue: Float) {
        let nsColor = NSColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        // Use `usingColorSpace` to ensure we get the correct RGB values.
        if let convertedColor = nsColor.usingColorSpace(.sRGB) {
            convertedColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        }
        return (Float(red), Float(green), Float(blue))
    }
    
    /// Updates the light bar color on the controller.
    private func updateLightBarColor(to color: Color) {
        guard let controller = self.connectedController else { return }
        let components = getRGBAComponents(from: color)
        // Use the `light` property's `color` attribute on the `GCController`.
        controller.light?.color = GCColor(red: components.red, green: components.green, blue: components.blue)
    }
    
    /// Converts a GCDeviceBattery.State enum to a readable string.
    private func getBatteryStateString(state: GCDeviceBattery.State) -> String {
        switch state {
        case .charging:
            return "Charging"
        case .discharging:
            return "Discharging"
        case .full:
            return "Full"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Updates the player index of the connected controller.
    private func updatePlayerIndex(to index: Int) {
        guard let controller = self.connectedController else { return }
        switch index {
        case 1: controller.playerIndex = .index1
        case 2: controller.playerIndex = .index2
        case 3: controller.playerIndex = .index3
        case 4: controller.playerIndex = .index4
        default: controller.playerIndex = .indexUnset
        }
        print("Updated player index to: \(index)")
    }

    func handleControllerDidConnect(_ controller: GCController) {
        // This line assigns a player index to your app, which should grant exclusive access.
        // The player index is now controlled by the slider, so we don't set a default here.
        self.connectedController = controller // Store a reference to the main controller
        updatePlayerIndex(to: Int(playerIndexSliderValue))
        
        if let dualSense = controller.extendedGamepad as? GCDualSenseGamepad {
            self.dualSense = dualSense
            setupDualSenseInputHandler(dualSense)
            // Immediately set the light bar color when a controller connects.
            updateLightBarColor(to: selectedLightBarColor)
        }
        
        // Update the initial battery status when a controller connects
        if let battery = controller.battery {
            DispatchQueue.main.async {
                self.dualSenseState.batteryLevel = battery.batteryLevel
                self.dualSenseState.batteryState = battery.batteryState
            }
        }
    }

    func handleControllerDidDisconnect(_ controller: GCController) {
        print("Controller disconnected.")
        self.dualSense = nil
        self.connectedController = nil
    }
    
    func setupControllerObservers() {
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect,
                                               object: nil,
                                               queue: .main) { notification in
            guard let controller = notification.object as? GCController else { return }
            self.handleControllerDidConnect(controller)
        }
        
        NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect,
                                               object: nil,
                                               queue: .main) { notification in
            guard let controller = notification.object as? GCController else { return }
            self.handleControllerDidDisconnect(controller)
        }
        
        for controller in GCController.controllers() {
            handleControllerDidConnect(controller)
        }
    }
    
    // New function to observe battery changes
    func setupBatteryObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name("GCDeviceBatteryDidChange"),
                                               object: nil,
                                               queue: .main) { notification in
            guard let battery = notification.object as? GCDeviceBattery else { return }
            DispatchQueue.main.async {
                self.dualSenseState.batteryLevel = battery.batteryLevel
                self.dualSenseState.batteryState = battery.batteryState
            }
        }
    }

    func setupDualSenseInputHandler(_ dualSense: GCDualSenseGamepad) {
        dualSense.valueChangedHandler = { gamepad, element in
            DispatchQueue.main.async {
                self.dualSenseState.isCrossPressed = dualSense.buttonA.isPressed
                self.dualSenseState.isCirclePressed = dualSense.buttonB.isPressed
                self.dualSenseState.isSquarePressed = dualSense.buttonX.isPressed
                self.dualSenseState.isTrianglePressed = dualSense.buttonY.isPressed
                
                self.dualSenseState.isDPadUp = dualSense.dpad.up.isPressed
                self.dualSenseState.isDPadDown = dualSense.dpad.down.isPressed
                self.dualSenseState.isDPadLeft = dualSense.dpad.left.isPressed
                self.dualSenseState.isDPadRight = dualSense.dpad.right.isPressed
                
                self.dualSenseState.leftStickX = dualSense.leftThumbstick.xAxis.value
                self.dualSenseState.leftStickY = dualSense.leftThumbstick.yAxis.value
                self.dualSenseState.rightStickX = dualSense.rightThumbstick.xAxis.value
                self.dualSenseState.rightStickY = dualSense.rightThumbstick.yAxis.value
                
                self.dualSenseState.isLeftBumperPressed = dualSense.leftShoulder.isPressed
                self.dualSenseState.isRightBumperPressed = dualSense.rightShoulder.isPressed
                self.dualSenseState.leftTriggerValue = dualSense.leftTrigger.value
                self.dualSenseState.rightTriggerValue = dualSense.rightTrigger.value
                
                self.dualSenseState.isLeftStickPressed = dualSense.leftThumbstickButton?.isPressed ?? false
                self.dualSenseState.isRightStickPressed = dualSense.rightThumbstickButton?.isPressed ?? false
                self.dualSenseState.isOptionsPressed = dualSense.buttonOptions!.isPressed
                self.dualSenseState.isMenuPressed = dualSense.buttonMenu.isPressed
                self.dualSenseState.isPlayStationPressed = dualSense.buttonHome?.isPressed ?? false
                self.dualSenseState.isTouchpadPressed = dualSense.touchpadButton.isPressed
            }
        }
    }
}
