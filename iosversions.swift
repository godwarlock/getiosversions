import UIKit
import Foundation
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

var request = URLRequest(url: URL(string: "https://api.ipsw.me/v4/devices?keysOnly=true")!)
request.httpMethod = "GET"

// MARK: - Device
struct Device: Codable {
    let name, identifier: String
    let boards: [Board]
    let boardconfig, platform: String
    let cpid, bdid: Int
    
    // MARK: - Board
    struct Board: Codable {
        let boardconfig, platform: String
        let cpid, bdid: Int
    }
}

typealias Devices = [Device]

// MARK: - Firmwares
struct DeviceFirmwares: Codable {
    let name: String
    let identifier: String
    let firmwares: [Firmware]
}

// MARK: - Firmware
struct Firmware: Codable {
    let identifier: String
    let version, buildid: String
}

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data, error == nil else {
        print("error=\(String(describing: error))")
        return
    }
    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
        print("statusCode should be 200, but is (httpStatus.statusCode)")
        print("response = \(String(describing: response))")
    }
    if String(data: data, encoding: String.Encoding.utf8) != nil {
        do {
            let group = DispatchGroup()
            var versions : [String : String] = [String : String]()
            var versionArray: [String] = [String]()
            let devices = try JSONDecoder().decode(Devices.self, from: data)
            for device in devices {
                group.enter()
                let deviceForDeviceURL = "https://api.ipsw.me/v4/device/" + device.identifier + "?type=ipsw"
                
                var deviceRequest = URLRequest(url: URL(string: deviceForDeviceURL)!)
                deviceRequest.httpMethod = "GET"
                
                let deviceTask = URLSession.shared.dataTask(with: deviceRequest) { data, response, error in
                    guard let data = data, error == nil else {
                        print("error=\(String(describing: error))")
                        return
                    }
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        print("statusCode should be 200, but is (httpStatus.statusCode)")
                        print("response = \(String(describing: response))")
                    }
                    if let body_response = String(data: data, encoding: String.Encoding.utf8) {
                        do {
                            let deviceFirmwares = try JSONDecoder().decode(DeviceFirmwares.self, from: data)
                            for deviceFirmware in deviceFirmwares.firmwares {
                                let version = deviceFirmware.version + "(\(deviceFirmware.buildid))"
                                versions[version] = ""
                            }
                        } catch let parseError {
                            print("JSON Error \(parseError.localizedDescription)")
                        }
                        group.leave()
                    }
                }
                deviceTask.resume()
            }
            
            group.notify(queue: .main) {
                print(versions.keys.sorted())
            }
        } catch let parseError {
            print("JSON Error \(parseError.localizedDescription)")
        }
        
    }
}
task.resume()
