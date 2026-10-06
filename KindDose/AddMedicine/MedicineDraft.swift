//
//  MedicineDraft.swift
//  KindDose
//

import Foundation

/// An in-progress, unsaved medicine entry. Every add method (scan, speak, type,
/// Health import) builds one of these and hands it to AddMedicineConfirmView —
/// nothing is written to SwiftData until the person taps Save there.
struct MedicineDraft: Identifiable, Hashable {
    var id = UUID()
    var name: String = ""
    var dose: String = ""
    var form: MedicineForm = .tablet
    var instructions: String = ""
    var photo: Data?
    var times: [DateComponents] = []
}
