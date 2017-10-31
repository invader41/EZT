//
//  ViewController.swift
//  EZT
//
//  Created by psy on 2017/10/18.
//  Copyright © 2017年 ETJ. All rights reserved.
//

import UIKit
import SVProgressHUD
import AFNetworking

class LoginViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var phoneView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var codeView: UIView!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var captchaContainerView: UIView!
    
    @IBOutlet weak var webView: UIWebView!
    
    var captchaView = CaptchaView()
    var code: NSString = ""
    var token: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let borderColor = UIColor.init(red: 233/255.0, green: 233/255.0, blue: 233/255.0, alpha: 1) .cgColor
        phoneView.layer.borderColor = borderColor
        passwordView.layer.borderColor = borderColor
        codeView.layer.borderColor = borderColor
        
        webView.scrollView.bounces = false
        
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.dark)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.setMaximumDismissTimeInterval(3)
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
        
        phoneTextField.text = UserDefaults.standard.string(forKey: "account")
        passwordTextField.text = UserDefaults.standard.string(forKey: "password")
        
        captchaView = CaptchaView.init(frame: CGRect.init(x: 0, y: 0, width: 60, height: 25))
        captchaView.isRotation = true
        captchaContainerView.addSubview(captchaView)
        captchaView.refreshCode { (str) in
            self.code = str
            print(str)
        }
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapClick(_:)))
        captchaView.addGestureRecognizer(tap)
    }
    
    @objc func tapClick(_ sender: UITapGestureRecognizer) {
        
        captchaView.refreshCode { (str) in
            self.code = str
            print(str)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func hideKeyboard(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
    @IBAction func forgetPassword(_ sender: UIButton) {
        let request = URLRequest.init(url: URL.init(string: "http://m.etuanjian.com/Manage/FindPassword/Index" )!)
        self.webView.loadRequest(request)
        SVProgressHUD.show()
    }
    @IBAction func login(_ sender: UIButton) {
        let account = phoneTextField.text
        let password = passwordTextField.text
        if ((account != nil) && (password != nil) && account!.count > 0 && password!.count > 0) {
            SVProgressHUD.show()
            let configuration = URLSessionConfiguration.default
            let manager = AFURLSessionManager.init(sessionConfiguration: configuration)
            let responseSerializer = AFHTTPResponseSerializer()
            responseSerializer.acceptableContentTypes = ["text/html"]
            manager.responseSerializer = responseSerializer
            let request = AFHTTPRequestSerializer().request(withMethod: "GET", urlString: "http://m.etuanjian.com/login/loginCheck", parameters: ["account":account, "password": password], error: nil)
            let dataTask = manager.dataTask(with: request as URLRequest, completionHandler: { (response, responseObject, error) in
                if ((error) != nil) {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    let rets = String.init(data: responseObject as! Data, encoding: String.Encoding.utf8)!.components(separatedBy: "|")
                    if (rets[0] == "0") {
                        SVProgressHUD.dismiss()
                        UserDefaults.standard.set(account!, forKey: "account")
                        UserDefaults.standard.set(password!, forKey: "password")
                        self.token = rets[1]
                        
                        let request = URLRequest.init(url: URL.init(string: "http://m.etuanjian.com/login/loginApp?token=\(self.token)" )!)
                        self.webView.loadRequest(request)
                        SVProgressHUD.show()
                        
                    } else {
                        SVProgressHUD.showError(withStatus: rets[0])
                    }
                }
            })
            dataTask.resume()
        } else {
            SVProgressHUD.showError(withStatus: "请输入账号与密码")
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.isHidden = false
        SVProgressHUD.dismiss()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        if((error as! URLError).code == URLError.cancelled)  {
            return;
        }
        let alertController = UIAlertController(title: "发生错误",
                                                message: error.localizedDescription, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "返回登录", style: .cancel, handler: {
            action in
            webView.isHidden = true
        })
        let okAction = UIAlertAction(title: "重试", style: .default, handler: {
            action in
            webView.reload()
        })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }

}

