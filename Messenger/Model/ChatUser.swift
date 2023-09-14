//
//  ChatUser.swift
//  Messenger
//
//  Created by Harsh Raghvani on 29/04/23.
//

import Foundation

struct ChatUser: Identifiable,Equatable{
    var id: String {uid}
    let uid,email,profileImageUrl :String
    
    init(data: [String: Any]){
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
    }
}
