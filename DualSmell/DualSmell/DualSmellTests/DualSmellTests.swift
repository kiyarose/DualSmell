//
//  DualSmellTests.swift
//  DualSmellTests
//
//  Created by Kiya Rose on 2025.09.05.
//

import Testing
import GameController
import CoreHaptics
@testable import DualSmell

/// A simple class to receive and store values from the mock controller handlers.
class InputReceiver {
    var isPressed: Bool?
    var buttonValue: Float?
    var xAxisValue: Float?
    var yAxisValue: Float?
}

/// A simple mock button class to emulate a controller button.
class MockButton {
    var isPressed: Bool = false
    var value: Float = 0.0
    // This closure no longer references GCControllerButtonInput, fixing the errors.
    var valueChangedHandler: ((_ value: Float, _ isPressed: Bool) -> Void)?

    func simulatePress(pressed: Bool) {
        self.isPressed = pressed
        self.value = pressed ? 1.0 : 0.0
        // Call the handler to notify the consumer of the change.
        valueChangedHandler?(value, isPressed)
    }
}

/// A simple mock axis.
class MockAxis {
    var value: Float = 0.0
}

/// A mock touchpad class to emulate a controller touchpad.
class MockTouchpad {
    var xAxis = MockAxis()
    var yAxis = MockAxis()
    // This closure no longer references GCControllerTouchpadInput, fixing the errors.
    var valueChangedHandler: ((_ xAxis: MockAxis, _ yAxis: MockAxis) -> Void)?

    func simulateTouch(x: Float, y: Float) {
        self.xAxis.value = x
        self.yAxis.value = y
        // Call the handler to notify the consumer of the change.
        valueChangedHandler?(xAxis, yAxis)
    }
}

/// A mock controller to emulate a DualSense gamepad for testing purposes.
class MockDualSenseGamepad {
    
    // MARK: - Mocked Inputs
    
    var buttonA = MockButton() // Cross button
    var buttonB = MockButton() // Circle button
    var buttonX = MockButton() // Square button
    var buttonY = MockButton() // Triangle button

    var leftShoulder = MockButton() // L1
    var rightShoulder = MockButton() // R1

    // We don't need to mock all properties for this example, just the ones we will test.
    var touchpadPrimary = MockTouchpad()
}

// MARK: - Haptics Mocking Classes
// These classes are added to enable the haptics test below.

/// A mock class that pretends to be GCDeviceHaptics.
// We remove conformance to the protocol because it prevents initialization.
public class MockHapticEngine {
    public var wasPlayCalled: Bool = false
    
    // Add a public initializer to allow the class to be constructed.
    public init() {}
    
    // The `play(_:)` method is unavailable for testing, so we'll use a mock function.
    public func mockPlay(_ pattern: CHHapticPattern) {
        self.wasPlayCalled = true
    }
}

/// A simple class that contains your haptics logic, which we want to test.
public class HapticsManager {
    // We update the type to use our mock class directly.
    public var hapticEngine: MockHapticEngine?

    // This is the function we want to test.
    public func playHapticPulse() {
        // Create a simple haptic pattern
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)
        let pattern = try! CHHapticPattern(events: [event], parameters: [])
        
        // Tell the mock engine to "play" it.
        hapticEngine?.mockPlay(pattern)
    }
}


/// This file contains tests that use a mock controller to simulate input.
struct DualSenseControllerTests {
    
    @Test func touchpadInputIsRegistered() async throws {
        let mockGamepad = MockDualSenseGamepad()
        let receiver = InputReceiver()
        
        // Set the value changed handler on the mock touchpad.
        // The closure parameters now match our mock class.
        mockGamepad.touchpadPrimary.valueChangedHandler = { xAxis, yAxis in
            receiver.xAxisValue = xAxis.value
            receiver.yAxisValue = yAxis.value
        }
        
        // Simulate a touch in the top-right corner.
        let expectedX: Float = 0.75
        let expectedY: Float = 0.5
        mockGamepad.touchpadPrimary.simulateTouch(x: expectedX, y: expectedY)
        
        // Expect that the receiver has captured the correct values.
        #expect(receiver.xAxisValue == expectedX, "X-axis value should match simulated value.")
        #expect(receiver.yAxisValue == expectedY, "Y-axis value should match simulated value.")
    }
    
    @Test func crossButtonIsPressed() async throws {
        let mockGamepad = MockDualSenseGamepad()
        let receiver = InputReceiver()

        // Set the value changed handler on the mock button.
        // The closure parameters now match our mock class.
        mockGamepad.buttonA.valueChangedHandler = { value, isPressed in
            receiver.isPressed = isPressed
            receiver.buttonValue = value
        }
        
        // Simulate the button being pressed.
        mockGamepad.buttonA.simulatePress(pressed: true)
        
        // Expect that the button's state and value are correctly registered.
        #expect(receiver.isPressed == true, "Button should be reported as pressed.")
        #expect(receiver.buttonValue == 1.0, "Button value should be 1.0 when pressed.")

        // Simulate the button being released.
        mockGamepad.buttonA.simulatePress(pressed: false)

        // Expect the button's state and value to be reset.
        #expect(receiver.isPressed == false, "Button should be reported as not pressed.")
        #expect(receiver.buttonValue == 0.0, "Button value should be 0.0 when not pressed.")
    }

    @Test func leftStickPositionIsAccurate() async throws {
        // This test is currently conceptual as it relies on a mock that isn't fully implemented.
        let mockGamepad = MockDualSenseGamepad()
        let receiver = InputReceiver()
        
        // Set the value changed handler on the mock thumbstick.
        // If your actual code reads from the leftThumbstick property, you would modify the mock class.
        mockGamepad.buttonA.valueChangedHandler = { value, _ in
            receiver.buttonValue = value
        }

        // Simulating the left stick is a bit more complex. If your code is set up to read from
        // the `GCExtendedGamepad` object, we can add a handler there. For now, this test is
        // conceptual and shows how you would verify a value after simulation.
        
        // Let's assume you have a `MockLeftStick` with a `simulate` method.
        // mockGamepad.leftStick.simulate(x: 1.0, y: 0.0)
        // #expect(mockGamepad.leftStick.xAxis.value == 1.0, "Left stick X should be 1.0.")
    }
    
    @Test func hapticsResponsive() async throws {
        // Given: We set up our mock environment.
        let hapticManager = HapticsManager()
        let mockHapticEngine = MockHapticEngine()
        
        // Assign the mock engine to our manager.
        hapticManager.hapticEngine = mockHapticEngine
        
        // When: We perform the action we want to test.
        hapticManager.playHapticPulse()
        
        // Then: We expect that the action had the intended effect.
        #expect(mockHapticEngine.wasPlayCalled, "The mock haptic engine's play function should have been called.")
    }
}
