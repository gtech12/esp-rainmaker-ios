// Copyright 2020 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  ScannerViewController.swift
//  ESPRainMaker
//
//  Created by Vikas Chandra on 26/11/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import AVFoundation
import ESPProvision
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import UIKit

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer?
    var provisionConfig: [String: String] = [:]
    @IBOutlet var scannerView: UIView!
    @IBOutlet var addManuallyButton: PrimaryButton!
    @IBOutlet var scannerHeading: UILabel!
    @IBOutlet var scannerDescription: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        scanQrCode()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = scannerView.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func scanQrCode() {
        ESPProvisionManager.shared.scanQRCode(scanView: scannerView) { espDevice, _ in
            if let device = espDevice {
                DispatchQueue.main.async {
                    Utility.showLoader(message: "Connecting to device", view: self.view)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.connectDevice(espDevice: device)
                }
            } else {
                DispatchQueue.main.async {
                    self.retry(message: "Device could not be scanned. Please try again")
                    print("Failed to scane")
                }
            }
        }
    }

    func connectDevice(espDevice: ESPDevice) {
        espDevice.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            switch status {
            case .connected:
                DispatchQueue.main.async {
                    self.goToProvision(device: espDevice)
                }
                print("Connected to device")
            default:
                DispatchQueue.main.async {
                    self.retry(message: "Device could not be connected. Please try again")
                    print("Failed to connect")
                }
            }
        }
    }

    @IBAction func cancelClickecd(_: Any) {
        navigationController?.popToRootViewController(animated: false)
    }

    func retry(message: String) {
        Utility.hideLoader(view: view)
        addManuallyButton.isEnabled = true
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            DispatchQueue.main.async {
                self.scanQrCode()
            }
        }))
        present(alertController, animated: true, completion: nil)
    }

    func goToProvision(device: ESPDevice) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.connectAutomatically = true
            provisionVC.isScanFlow = true
            provisionVC.device = device
            provisionVC.provisionConfig = self.provisionConfig
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
    func showAlertWith(message: String = "") {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension ScannerViewController: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice _: ESPDevice) -> String? {
        return nil
    }
}
