//
//  ContentView.swift
//  Messenger
//
//  Created by Harsh Raghvani on 26/04/23.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
class FirebaseManager: NSObject{
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    static let shared = FirebaseManager()
    override init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        super.init()
    }
}

struct ContentView: View {
    @State var isLoginMode = false
    @State var emailString = ""
    @State var password = ""
    
    @State var shouldShowImagePicker = false
    
//    init(){
//        FirebaseApp.configure()
//    }
    var body: some View {
        NavigationView{
            ScrollView{
                VStack{
                    Picker(selection: $isLoginMode,  label: Text("Picker Here")){
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    if !isLoginMode{
                        Button{
                            shouldShowImagePicker.toggle()
                        }label: {
                            
                            VStack{
                                if let image = self.image{
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                    
                                } else
                                {
                                    Image(systemName: "person.fill")
                                        .padding()
                                        .font(.system(size: 64))
                                        .foregroundColor(Color(.label))
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black,lineWidth: 3))
                                //.padding()
                        }
                    }
                    Group{
                        TextField("Email", text: $emailString)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.none)
                            .padding()
                        SecureField("Password", text: $password)
                            .padding()
                    }
                    .background(Color.white)
                    .padding(6)
                    
                    
                    Button{
                        if(isLoginMode){
                            loginUser()
                        }
                        else{
                            createNewAccount()
                        }
                    }label: {
                        HStack{
                            Spacer()
                            Text(isLoginMode ? "Login":"Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical,10)
                                .font(.system(size: 14,weight: .semibold))
                            Spacer()
                        }
                        .background(.blue)
                        .padding()
                    }
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                    
                }
                .navigationTitle(isLoginMode ? "Log In":"Create Account")
                
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .background(Color(.init(white: 0, alpha: 0.05)))
            .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
                ImagePicker(image: $image)
            }
            
        }
    }
    private func handleAction(){
        if isLoginMode{
            print("Should Login into firebase with existing creds.")
        }
        else{
            createNewAccount()
            print("Register a new account inside of firebase Auth and then store Image")
        }
    }
    @State var loginStatusMessage = ""
    
    @State var image : UIImage?
    
    private func loginUser(){
        FirebaseManager.shared.auth.signIn(withEmail: emailString, password: password){
            result, err in
            if let err = err{
                print("Failed to login User:",err)
                self.loginStatusMessage="Failed to login User: \(err)"
                return
            }
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
        }
    }
    
    private func persistImageToStorage(){
       // let filename = UUID().uuidString
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else{return}
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5)
        else{return}
        
                ref.putData(imageData,metadata: nil){
                    metadata, err in
                    if let err = err{
                        self.loginStatusMessage = "Failed to push image to Storage:\(err)"
                        return
                    }
                    ref.downloadURL(){
                        url,err in
                        if let err = err{
                            self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                            return
                        }
                        self.loginStatusMessage = "Successfully stored image with url \(url?.absoluteString ?? "")"
                    }
                }
    }
    
    private func createNewAccount(){
        FirebaseManager.shared.auth.createUser(withEmail: self.emailString, password: self.password){
            result, err in
            if let err = err{
                //print("Failed to create user: ",err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("Succressfully created user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Succressfully created user: \(result?.user.uid ?? "")"
            persistImageToStorage()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
