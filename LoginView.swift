//
//  ContentView.swift
//  ST_Chat
//
//  Created by Siddhesh on 14/02/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct LoginView: View {
    let didCompleteLoginProcess: () -> ()
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var shouldShowImagePicker = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var image: UIImage?
    @State private var loginStatusMessage = ""
    @State private var isPasswordVisible = false
    
    var body: some View {
        NavigationView {
            VStack {
                Picker(selection: $isLoginMode, label: Text("Picker here")) {
                    Text("Login")
                        .tag(true)
                    Text("Create Account")
                        .tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                
                if !isLoginMode {
                    Button(action: {
                        shouldShowImagePicker.toggle()
                    }) {
                        AvatarView(image: $image)
                    }
                    .padding(.top, 20)
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                Group {
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                    } else {
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                    }
                }
                
                Toggle("Show Password", isOn: $isPasswordVisible)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                Button(action: {
                    handleTap()
                }) {
                    Text(isLoginMode ? "Log In" : "Create Account")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                
                Text(loginStatusMessage)
                    .foregroundColor(.red)
                    .padding(.top, 20)
            }
            .navigationTitle(isLoginMode ? "Login" : "Create Account")
            .background(Color(.init(white:0,alpha:0.05)))
            .ignoresSafeArea()
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    
    }
    
    private func handleTap() {
        isLoginMode ? loginUser() : createNewAccount()
    }
    
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                self.alertTitle = "Error"
                self.alertMessage = "Failed to create user: \(err.localizedDescription)"
                self.showAlert.toggle()
                return
            }
            
            self.alertTitle = "Success"
            self.alertMessage = "Successfully created user"
            self.showAlert.toggle()
            self.persistImageToStorage()
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                self.alertTitle = "Error"
                self.alertMessage = "Failed to login user: \(err.localizedDescription)"
                self.showAlert.toggle()
                return
            }
            
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            self.didCompleteLoginProcess()
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err.localizedDescription)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err.localizedDescription)"
                    return
                }
                
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
                guard let url = url else { return }
                self.storeInfo(imageProfileUrl:url)
            }
        }
    }
    
    private func storeInfo(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let userData = [
            "email": self.email,
            "uid": uid,
            "profileImageUrl": imageProfileUrl.absoluteString
        ]
        
        FirebaseManager.shared.firestore.collection("users").document(uid).setData(userData) { err in
            if let err = err {
                print(err.localizedDescription)
                self.loginStatusMessage = "\(err.localizedDescription)"
                return
            }
            print("Successfully stored")
            self.didCompleteLoginProcess()
        }
    }
}

struct AvatarView: View {
    @Binding var image: UIImage?
    
    var body: some View {
        VStack {
            if let image = self.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128, height: 128)
                    .cornerRadius(64)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 64))
                    .padding()
                    .foregroundColor(Color(.label))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black,lineWidth: 3))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {})
    }
}
