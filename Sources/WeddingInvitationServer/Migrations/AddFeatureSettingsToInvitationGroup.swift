//
//  AddFeatureSettingsToInvitationGroup.swift
//  WeddingInvitationServer
//
//  Created by zzzzych on 7/28/25.
//

import Fluent

struct AddFeatureSettingsToInvitationGroup: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("invitation_groups")
            .field("show_venue_info", .bool)
            .field("show_share_button", .bool)
            .field("show_ceremony_program", .bool)
            .field("show_rsvp_form", .bool)
            .field("show_account_info", .bool)
            .field("show_photo_gallery", .bool)
            .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("invitation_groups")
            .deleteField("show_venue_info")
            .deleteField("show_share_button")
            .deleteField("show_ceremony_program")
            .deleteField("show_rsvp_form")
            .deleteField("show_account_info")
            .deleteField("show_photo_gallery")
            .update()
    }
}
