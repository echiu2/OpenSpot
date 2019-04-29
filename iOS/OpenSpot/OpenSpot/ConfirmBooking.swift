//
//  ConfirmBooking.swift
//  OpenSpot
//
//  Created by Stephen Fung on 4/19/19.
//  Copyright © 2019 Jay Lliguichushca. All rights reserved.
//
import UIKit
import Firebase
import GoogleMaps
import MapKit

class ConfirmBooking: UIViewController, UIPickerViewDataSource{
    @IBOutlet weak var drivewayMapView: GMSMapView!
    @IBOutlet weak var drivewayLocationLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    //    @IBOutlet weak var drivewayOwnerLabel: UILabel!
    //    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var selectCarTextField: UITextField!
    @IBOutlet weak var bookDrivewayButton: UIButton!
    
    //default value that is overwritten by FirstViewControllerVC
    lazy var coord = CLLocationCoordinate2D(latitude: 43.0008, longitude: 78.7890)
    var locationName = String?("")
    var price = String?("")
    var drivewayOwnerName = String?("")
    var phoneNumber = String?("")
    var carsArray: [String] = ["-SELECT-"]
    let db = Firestore.firestore()
    let currentUser = Auth.auth().currentUser
    var carPicker = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectCarTextField.underlined()
        getCarsArray()
        setUpView()
        
        carPicker.delegate = self
        carPicker.dataSource = self
        selectCarTextField.inputView = carPicker
    }
    
    func getCarsArray(){
        db.collection("Users").document((currentUser?.uid)!).getDocument { (value, Error) in
            var tempArray = value!["Cars"] as! [String]
            var index = 0
            while index < tempArray.count{
                self.carsArray += [tempArray[index] + " " + tempArray[index + 1] + " - " + tempArray[index + 4]]
                index += 5
            }
        }
    }
    
    func setUpView(){
        priceLabel.text = price
        drivewayLocationLabel.text = locationName
        let camera = GMSCameraPosition.camera(withLatitude: coord.latitude, longitude: coord.longitude, zoom: 16)
        drivewayMapView?.camera = camera
        
        let marker = GMSMarker(position: coord)
        marker.map = drivewayMapView
        drivewayMapView.settings.setAllGesturesEnabled(false)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(dismissVC))
        //        callButton.addTarget(self, action: #selector(clickCallButton), for: .touchUpInside)
        bookDrivewayButton.addTarget(self, action: #selector(bookDriveway), for: .touchUpInside)
        
        //        drivewayOwnerLabel.text = drivewayOwnerName! + "'s driveway"
    }
    
    @objc func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //    @objc func clickCallButton() {
    //        if let url = URL(string: "tel://\(phoneNumber!)") {
    //            UIApplication.shared.open(url, options: [:], completionHandler: nil)
    //        }
    //    }
    
    func getDate() -> String{
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day,.year], from: date)
        let month = components.month
        let day = components.day
        let year = components.year
        print(month as Any)
        print(day as Any)
        return months[month!-1] + " " + String(day ?? 1) + ", " + String(year ?? 2019)
    }
    
    func getTime() -> String{
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour,.minute], from: date)
        let hour = components.hour
        let minute = components.minute
        return String(hour ?? 12) + ":" + String(minute ?? 00)
    }
    
    @objc func bookDriveway(){
        //        var check = false
        if(selectCarTextField.text == "" || selectCarTextField.text == "-SELECT-"){
            let alertController = UIAlertController(title: "OpenSpot", message: "Please select a car", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            //            check=true
            var documentID = ""
            let database1 = db.collection("Users")
            var updatedAddress1 = [String]()
            database1.getDocuments{ (value, error) in
                for account in value!.documents{
                    let address = account.data()["Addresses"] as? [String]
                    if address != nil && address!.count > 0{
                        var updatedAddress = address
                        var index = 0
                        while index != address!.count{
                            if ((address![index + 1] == String(self.coord.latitude)) && (address![index + 2] == String(self.coord.longitude))){
                                documentID = account.documentID
                                updatedAddress![index + 3] = "0"
                                //                                updatedAddress = [address![index],address![index + 1],address![index + 2],address![index + 3],"0" ]
                                updatedAddress1 = updatedAddress!
                                break
                            }
                            index += 5
                        }
                    }
                }
                
                database1.document(documentID).updateData([
                    "Addresses": updatedAddress1,
                    ])
                let currentAddress = updatedAddress1[0]
                let getPrice = updatedAddress1[4]
                let date = self.getDate()
                let time = self.getTime()
                
                let user = self.db.collection("Users").document((self.currentUser?.uid)!)
                var reservationsArray = [String]()
                user.getDocument { (value, Error) in
                    reservationsArray = (value!["Reservations"] as? [String])!
                    reservationsArray.append(currentAddress)
                    reservationsArray.append(getPrice)
                    reservationsArray.append(date)
                    reservationsArray.append(time)
                    reservationsArray.append("5.0")
                    user.updateData([
                        "Reservations":reservationsArray,
                        ])
                }
                
                
            }
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
}

extension ConfirmBooking: GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        let source = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        source.name = locationName
        MKMapItem.openMaps(with: [source], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let source = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        source.name = locationName
        MKMapItem.openMaps(with: [source], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        return true
    }
}

extension ConfirmBooking: UIPickerViewDelegate{
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return carsArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectCarTextField.text = carsArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return carsArray[row]
    }
}
