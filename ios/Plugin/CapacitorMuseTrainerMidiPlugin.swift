import Foundation
import Capacitor
import MIKMIDI

@objc(CapacitorMuseTrainerMidiPlugin)
public class CapacitorMuseTrainerMidiPlugin: CAPPlugin {
    var midiDevicesObserver: NSKeyValueObservation?
    let deviceManager = MIKMIDIDeviceManager.shared
    
    func validDevice(dv: MIKMIDIDevice) -> Bool {
        !dv.isVirtual && dv.entities.count > 0 && !(dv.manufacturer ?? "").isEmpty
    }
    
    override public func load() {
        midiDevicesObserver = deviceManager.observe(\.availableDevices) { (dm, _) in
            // Devices change
            let d = Dictionary.init(uniqueKeysWithValues: dm.availableDevices
                .filter(self.validDevice)
                .enumerated()
                .map({ (String($0), $1.manufacturer ?? "") }))
            self.notifyListeners("deviceChange", data: d)
            
            // Listen to MIDI events from all sources
            for device in self.deviceManager.availableDevices.filter(self.validDevice) {
                for entity in device.entities {
                    for source in entity.sources {
                        do {
                            try self.deviceManager.connectInput(source, eventHandler: { (_, cmds) in
                                for cmd in cmds {
                                    var cmdStr: String
                                    switch cmd.commandType {
                                    case .noteOff:
                                        cmdStr = "noteOff"
                                    case .noteOn:
                                        cmdStr = "noteOn"
                                    case .polyphonicKeyPressure:
                                        cmdStr = "polyphonicKeyPressure"
                                    case .controlChange:
                                        cmdStr = "controlChage"
                                    case .programChange:
                                        cmdStr = "programChange"
                                    case .channelPressure:
                                        cmdStr = "channelPressure"
                                    case .pitchWheelChange:
                                        cmdStr = "pitchWheelChange"
                                    case .systemMessage:
                                        cmdStr = "systemMessage"
                                    case .systemExclusive:
                                        cmdStr = "systemExclusive"
                                    case .systemTimecodeQuarterFrame:
                                        cmdStr = "systemTimecodeQuarterFrame"
                                    case .systemSongPositionPointer:
                                        cmdStr = "systemSongPositionPointer"
                                    case .systemSongSelect:
                                        cmdStr = "systemSongSelect"
                                    case .systemTuneRequest:
                                        cmdStr = "systemTuneRequest"
                                    case .systemTimingClock:
                                        cmdStr = "systemTimingClock"
                                    case .systemStartSequence:
                                        cmdStr = "systemStartSequence"
                                    case .systemContinueSequence:
                                        cmdStr = "systemContinueSequence"
                                    case .systemStopSequence:
                                        cmdStr = "systemStopSequence"
                                    case .systemKeepAlive:
                                        cmdStr = "systemKeepAlive"
                                    @unknown default:
                                        cmdStr = "unknown"
                                    }
                                    
                                    self.notifyListeners("commandSend", data: [
                                        "command": cmdStr,
                                        "dataByte1": cmd.dataByte1,
                                        "dataByte2": cmd.dataByte2
                                    ])
                                }
                            })
                        } catch {
                            self.notifyListeners("connectError", data: [source.displayName ?? "Unknown": String(describing: error)])
                        }
                    }
                }
            }
        }
    }
    
    @objc func listDevices(_ call: CAPPluginCall) {
        call.resolve([
            "devices": MIKMIDIDeviceManager.shared.availableDevices
                .filter(self.validDevice)
                .enumerated()
                .map({ (String($0), $1.manufacturer ?? "") })
        ])
    }
}
