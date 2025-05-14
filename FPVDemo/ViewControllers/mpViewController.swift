//
//  mpViewController.swift
//  DroneMLSwift
//
//  Created by Fahim Hasan Khan on 6/29/23.
//  Copyright © 2023 DJI. All rights reserved.
//

import Foundation
import UIKit

class mpViewController: UIViewController {
    
    @IBOutlet weak var pointAalt: UITextField!
    @IBOutlet weak var pointBalt: UITextField!
    @IBOutlet weak var c1alt: UITextField!
    @IBOutlet weak var c2alt: UITextField!
    @IBOutlet weak var c1rad: UITextField!
    @IBOutlet weak var c2rad: UITextField!
    @IBOutlet weak var coord: UILabel!
    var dataPassed: String!
    var dataToPass1: String!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let wpAlt = ";" + (pointAalt.text ?? "null") + ";" + (pointBalt.text ?? "null")
        let cAlt = ";" + (c1alt.text ?? "null") + ";" + (c1rad.text ?? "null")
        let cRad = ";" + (c2alt.text ?? "null") + ";" + (c2rad.text ?? "null")

        dataToPass1 = dataPassed +  wpAlt + cAlt + cRad

        if segue.identifier == "toMission" {
            let FPVViewController1 = segue.destination as! FPVViewController1
            FPVViewController1.dataPassed1 = dataToPass1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coord.text = dataPassed
    }
    
}
