//
//  NewMessageView.swift
//  Messenger
//
//  Created by Harsh Raghvani on 29/04/23.
//

import SwiftUI
import SDWebImageSwiftUI

class NewMessageViewModel: ObservableObject{
    @Published var users = [ChatUser]()
    @State var errorMessage = ""
    init(){
        fetchAllUsers()
    }
    private func fetchAllUsers(){
        FirebaseManager.shared.firestore.collection("users")
            .getDocuments{
                docsnapshot,error in
                if let error = error{
                    self.errorMessage = "Failed to fetch users: \(error)"
                    print("Failed to fetch users: \(error)")
                    return
                }
                docsnapshot?.documents.forEach({
                    snapshot in
                    let data = snapshot.data()
                    self.users.append(.init(data: data))
                })
            }
        self.errorMessage = "Fetched users successfully."
        
    }
}

struct NewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @ObservedObject var vm = NewMessageViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    var showChatLogView = false
    
    var body: some View {
        NavigationView{
            ScrollView{
                Text(vm.errorMessage)
                ForEach(vm.users){
                    user in
                    VStack{
                        Button{
                            presentationMode.wrappedValue.dismiss()
                            didSelectNewUser(user)
                        } label: {
                            HStack(spacing: 16){
                                let url = user.profileImageUrl
                                if(url==""){
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Color(.label))
                                        .font(.system(size: 32))
                                        .padding(8)
                                        .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label),lineWidth: 1))
                                }
                                else{
                                    let profilePic = WebImage(url: URL(string: url))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50,height: 50)
                                        .clipped()
                                        .cornerRadius(44)
                                        .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label),lineWidth: 1))
                                        .shadow(radius: 5)
                                    profilePic
                                    
                                }
                                Text(user.email)
                                    .foregroundColor(Color(.label))
                                    .font(.system(size: 16))
                                Spacer()
                            }
                        }
                        Divider()
                            .padding(.vertical,8)
                    }.padding(.horizontal)
                }
            }
            .navigationTitle("New Message")
            .toolbar{
                ToolbarItemGroup(placement: .navigationBarLeading){
                    Button{
                        presentationMode.wrappedValue.dismiss()
                    }label: {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        //NewMessageView(didSelectNewUser: {})
        MainMessagesView()
    }
}
