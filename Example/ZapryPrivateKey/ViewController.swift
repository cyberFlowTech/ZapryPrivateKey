//
//  ViewController.swift
//  ZapryPrivateKey
//
//  Created by 285275534 on 08/18/2024.
//  Copyright (c) 2024 285275534. All rights reserved.
//

import UIKit
import ZapryPrivateKey

class ViewController: UIViewController {

    @IBOutlet var privateKeyLabel: UILabel!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onButtonClick(){
        let helper = PrivateKeyHelper()
        privateKeyLabel.text = helper.createKey()
    }

}

