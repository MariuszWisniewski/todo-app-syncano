//
//  String+localization.swift
//  todo-app-syncano
//
//  Created by Mariusz Wisniewski on 8/14/15.
//  Copyright (c) 2015 Mariusz Wisniewski. All rights reserved.
//

extension String {
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: comment)
    }
}
