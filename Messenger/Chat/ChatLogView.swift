//
//  ChatLogView.swift
//  Messenger
//
//  Created by Harsh Raghvani on 30/04/23.
//

import SwiftUI

struct ChatMessage: Identifiable{
    var id: String{documentId}
    let documentId: String
    let fromId,toId,text,timestamp: String
    
    init(documentId: String,data: [String:Any]) {
        self.documentId = documentId
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.text = data["text"] as? String ?? ""
        self.timestamp=data["timeStamp"] as? String ?? ""
    }
}

import Firebase
class ChatLogViewModel: ObservableObject{
    @Published var count = 0
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage]()
    
    var toUser: ChatUser?
    init(inUser: ChatUser?){
        self.toUser = inUser
        fetchMessages()
    }
    
    func fetchMessages(){
        
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid
        else{return}
        guard let toId = toUser?.uid else{return}
        
        let document = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timeStamp")
            .addSnapshotListener{
                querySnapshot, error in
                if let error = error{
                    self.errorMessage = "Failed to listen for messages: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach{
                    change in
                    let data = change.document.data()
                    self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                }
                DispatchQueue.main.async {
                    self.count+=1
                }
//                querySnapshot?.documents.forEach({queryDocumentSnapshot in
//                    let data = queryDocumentSnapshot.data()
//                    let docId = queryDocumentSnapshot.documentID
//                    self.chatMessages.append(.init(documentId: ,data: data))
//                })
            }
    }
    
    func handleSend(text: String){
        print(text)
    let temp:String = text
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else{return}
        
        guard let toId = toUser?.uid else {return}
        let document =
        FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        let messageData = ["fromId":fromId,"toId":toId,"text":self.chatText,"timeStamp":Timestamp()] as [String : Any]
        document.setData(messageData){
            error in
            if let error = error {
                self.errorMessage = "Failed to save message into firestore: \(error)"
                return
            }
            print("Successfully saved current user sending message")
            self.persistRecentMessage(rec_m : temp)
            self.count+=1
            
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        recipientMessageDocument.setData(messageData){
            error in
            if let error = error {
                self.errorMessage = "Failed to save message into firestore: \(error)"
                return
            }
            print("Recipient saved message as well")
        }
        
    }
    private func persistRecentMessage(rec_m : String){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else {return}
        guard let toId = toUser?.uid else {return}
        let document = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        let data = [
            "timestamp": Timestamp(),
            "text": rec_m,
            "fromId": uid,
            "toId": toId,
            "profileImageUrl": toUser?.profileImageUrl ?? "",
            "email": toUser?.email ?? ""
        ] as [String : Any]
        document.setData(data){
            error in
            if let error = error{
                self.errorMessage = "Failed to save recent message: \(error)"
                print("Failed to save recent messages: \(error)")
                return
            }
        }
        let datar = [
            "timestamp": Timestamp(),
            "text": rec_m,
            "fromId": uid,
            "toId": toId,
            "profileImageUrl": FirebaseManager.shared.auth.currentUser?.photoURL ?? "",
            "email": toUser?.email ?? ""
        ] as [String : Any]
        
        
    }
    
}

struct ChatLogView: View {
   
//    let chatUser: ChatUser
//    init(chatUser: ChatUser) {
//        self.chatUser = chatUser
//        self.cm = ChatLogViewModel(inUser: chatUser)
//    }
    
    @ObservedObject var cm : ChatLogViewModel
    //@State var chatText = ""
    var body: some View {
        ZStack{
            Text("\(cm.errorMessage)")
            VStack{
                ScrollView{
                    ScrollViewReader{
                        scrollViewProxy in
                        VStack{
                            ForEach(cm.chatMessages){message in
                                    MessageView(message: message , chatUser: chatUser)
                                }
                            
                            HStack{Spacer()}
                                .id("empty")
                        }
                        .onReceive(cm.$count){_ in
                            withAnimation(.easeOut(duration: 0.5)){
                                scrollViewProxy.scrollTo("empty",anchor: .bottom)
                            }
                        }
                }
                    
                }
                .background(Color(.init(white: 0.3, alpha: 0.1)))
                //.padding(.vertical,1)
                .safeAreaInset(edge: .bottom){
                    HStack(){
                        Button{
                            
                        }label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 24))
                                .foregroundColor(Color(.darkGray))
                        }
                        ZStack{
                            HStack{
                                Text("Description")
                                    .foregroundColor(Color(.gray))
                                    .font(.system(size: 17))
                                    .padding(.leading, 5)
                                    .padding(.top, -4)
                                Spacer()
                            }
                            TextEditor(text: $cm.chatText)
                                .opacity(cm.chatText.isEmpty ? 0.5:1)
                        }.frame(height: 41)
                        
                        Button{
                            if(cm.chatText.isEmpty){}
                            else{
                                cm.handleSend(text: cm.chatText)
                                cm.chatText=""
                            }
                            
                        }label: {
                            Text("Send")
                                .foregroundColor(Color.white)
                        }
                        .padding(.horizontal)
                        .padding(.vertical,8)
                        .background(Color.blue)
                        .cornerRadius(4)
                    }
                    .padding(.horizontal)
                    .padding(.vertical,8)
                    .background(Color(.systemBackground).ignoresSafeArea())
                }
                
                
            }
            
        }
        .navigationTitle("\(chatUser.email)")
        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarItems(trailing: Button(action: {
//            cm.count+=1
//        }, label: {
//            Text("\(cm.count)")
//        }))
            
            
           // .font(.system(size: 20)) 
    }
}
struct MessageView: View{
    let message: ChatMessage
    //let chatUser: ChatUser
    var body: some View{
        VStack{
            if(message.fromId==FirebaseManager.shared.auth.currentUser?.uid){
                HStack{
                    //Spacer()
                    HStack{
                            Text("\(message.text)")
                                .foregroundColor(Color.black)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer()
                }
            }
            else{
                HStack{
                    Spacer()
                    HStack{
                            Text("\(message.text)")
                                .foregroundColor(Color.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                   // Spacer()
                }
            }
    }
        .padding(.horizontal)
        .padding(.bottom,8)
    }
}
struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            ChatLogView(chatUser: ChatUser.init(data: ["email":"harshraghvani697@gmail.com","uid":"Real User id"]))
        }
        //MainMessagesView()
    }
}
