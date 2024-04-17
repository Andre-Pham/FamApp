//
//  FamDatePicker.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

class FamDatePicker: FamUIView {
    
    private let datePicker = UIDatePicker()
    private var onDatePicked: ((_ date: Date) -> Void)? = nil
    public var date: Date {
        return self.datePicker.date
    }
    public var view: UIView {
        return self.datePicker
    }
    
    override init() {
        super.init()
        self.datePicker.translatesAutoresizingMaskIntoConstraints = false
        self.datePicker.locale = .current
        self.datePicker.date = Date()
        self.datePicker.preferredDatePickerStyle = .compact
        self.datePicker.datePickerMode = .dateAndTime
        self.datePicker.addTarget(self, action: #selector(self.onDatePickedCallback), for: .valueChanged)
    }
    
    @discardableResult
    func setOnDatePicked(_ callback: ((_ date: Date) -> Void)?) -> Self {
        self.onDatePicked = callback
        return self
    }
    
    @discardableResult
    func setDate(to date: Date) -> Self {
        self.datePicker.date = date
        return self
    }
    
    @discardableResult
    func setLocale(to locale: Locale?) -> Self {
        self.datePicker.locale = locale
        return self
    }
    
    @discardableResult
    func setPickerStyle(to style: UIDatePickerStyle) -> Self {
        self.datePicker.preferredDatePickerStyle = style
        return self
    }
    
    @discardableResult
    func setDatePickerMode(to mode: UIDatePicker.Mode) -> Self {
        self.datePicker.datePickerMode = mode
        return self
    }
    
    @objc private func onDatePickedCallback(_ datePicker: UIDatePicker) {
        self.onDatePicked?(datePicker.date)
    }
    
}

