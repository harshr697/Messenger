//
//  MainMessagesView.swift
//  Messenger
//
//  Created by Harsh Raghvani on 28/04/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct RecentMessages: Identifiable{
    var id:String{
        documentId
    }
    let documentId: String
    let text , fromId, toId,profileImageUrl,email:String
    let timestamp: Timestamp
    
    init(documentId: String, data: [String:Any]) {
        self.documentId = documentId
        self.text = data["text"] as? String ?? ""
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.email = data["email"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
    }
}

class MainMessagesViewModel: ObservableObject{
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    
    init(){
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = (FirebaseManager.shared.auth.currentUser?.uid == nil)
        }
        fetchCurrentUser()
        fetchRecentMessages()
        
    }
    @Published var recentMessages = [RecentMessages]()
    private func fetchRecentMessages(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .addSnapshotListener{
                querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen recent messages: \(error)"
                    print(error)
                    return
                }
                querySnapshot?.documentChanges.forEach({
                    change in
                    self.recentMessages.append(.init(documentId: change.document.documentID, data: change.document.data()))
                })
            }
    }
    
    func fetchCurrentUser(){
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else{
            self.errorMessage = "Could not find firebse uid"
            return}
        
//        guard let uid = result?.uid else{
//            self.errorMessage = "Could not find firebse uid"
//            return}
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument{ snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch current user: \(error)"
                print("Failed to fetch current user: ", error)
                return
            }
            guard let data = snapshot?.data() else {
                self.errorMessage = "No Data Found"
                return}
//            print(data)
            self.errorMessage = "Data: \(data.description)"
            
            self.chatUser = ChatUser.init(data: data)
            
           // self.errorMessage = chatUser.profileImageUrl
        }
    }
    @Published var isUserCurrentlyLoggedOut = false
    func handleSignOut(){
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    private var chatLogViewModel = ChatLogViewModel(inUser: nil)
    @State var shouldShowLogOutOptions = false
    
    @State var UsersList = [ChatUser]()
    
    @ObservedObject private var nm = MainMessagesViewModel()
    private var customNavBar: some View{
        HStack{
        let url = URL(string: nm.chatUser?.profileImageUrl ?? "")
            let defaultPic = Image(systemName: "person.fill")
                .font(.system(size: 34,weight: .heavy))
                .frame(width: 50,height: 50)
                .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label),lineWidth: 1))
            let profilePic = WebImage(url: url )
                .resizable()
                .scaledToFill()
                .frame(width: 50,height: 50)
                .clipped()
                .cornerRadius(44)
                .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label),lineWidth: 1))
                .shadow(radius: 5)
            if(url==URL(string: "")){
                defaultPic
            }
            else{
                profilePic
            }
            
            
//            Image(systemName: "person.fill")
//                .font(.system(size: 34,weight: .heavy))
            
            
            VStack(alignment: .leading,spacing: 4){
                let email = nm.chatUser?.email ?? ""
                Text("\(email)")
                    .font(.system(size: 24,weight: .bold))
                HStack(spacing: 0){
                    Image(systemName: "circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 10))
                    Text("online")
                        .font(.system(size: 10))
                        .foregroundColor(Color(.lightGray))
                }
                
            }
            Spacer()
            Button{
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24,weight: .bold))
                    .foregroundColor(Color(.label))
            }
            
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions){
            .init(title: Text("Settings"),message: Text("What do you want to do?"),buttons: [.destructive(Text("Sign Out"),action: {
                nm.handleSignOut()
            }),.cancel()])
        }
        .fullScreenCover(isPresented: $nm.isUserCurrentlyLoggedOut,onDismiss: nil){
            ContentView()
        }
        
    }
    @State var shouldShowNewMessageView = false
    private var newMessageButton: some View{
        Button{
            shouldShowNewMessageView.toggle()
        } label: {
            HStack{
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16,weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageView){
            NewMessageView(didSelectNewUser: {
                user in
                self.shouldNavigateToChatLogView.toggle()
                //self.chatUser = user
                self.chatLogViewModel.toUser = user
                self.chatLogViewModel.fetchMessages()
                
                print(user.email)
            })
        }
    }
    var chatUser: ChatUser?
    private var MessageView: some View{
        ScrollView{
            ForEach(nm.recentMessages){
                rm in
                VStack{
//                    NavigationLink(destination: ChatLogView(chatUser: user),isActive: $shouldNavigateToChatLogView){
                        HStack(spacing: 16){
                            
                            let url = rm.profileImageUrl
                            if(url==""){
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color(.label))
                                    .font(.system(size: 32))
                                    .padding(8)
                                    .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label),lineWidth: 1))
                            }
                            else{
                                let profilePic = WebImage(url: URL(string: url) )
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50,height: 50)
                                    .clipped()
                                    .cornerRadius(44)
                                    .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label),lineWidth: 1))
                                    .shadow(radius: 5)
                                profilePic
                            }
                            VStack(alignment: .leading){
                                Text("\(rm.email)")
                                    .font(.system(size: 16,weight: .bold))
                                    .foregroundColor(Color(.label))
                                Text("\(rm.text)")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.lightGray))
                            }
                            Spacer()
                            Text("22d")
                                .font(.system(size: 14,weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                    }
                    Divider()
                        .padding(.vertical,8)
                    
                }.padding(.horizontal)
                
            }.padding(.bottom, 50)
        //}
    }
    
    @State var shouldNavigateToChatLogView = false
    var body: some View{
        NavigationView{
            
            //Navigation Bar
            VStack{
                //Text("Current User ID \(nm.chatUser?.uid ?? "")")
                customNavBar
                Divider()
                MessageView
                NavigationLink("",isActive: $shouldNavigateToChatLogView){
                    ChatLogView(cm: chatLogViewModel)
                }

            }
            .overlay(newMessageButton,alignment: .bottom)
            .navigationBarHidden(true)
//            .navigationTitle("Main Message View")
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
