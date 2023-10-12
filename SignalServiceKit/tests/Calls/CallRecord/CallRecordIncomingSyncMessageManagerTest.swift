//
// Copyright 2023 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import LibSignalClient
import XCTest

@testable import SignalServiceKit

final class CallRecordIncomingSyncMessageManagerTest: XCTestCase {
    private var mockCallRecordStore: MockCallRecordStore!
    private var mockIndividualCallRecordManager: MockIndividualCallRecordManager!
    private var mockInteractionStore: MockInteractionStore!
    private var mockMarkAsReadShims: MockMarkAsReadShims!
    private var mockRecipientStore: MockRecipientStore!
    private var mockThreadStore: MockThreadStore!

    private var mockDB = MockDB()
    private var incomingSyncMessageManager: CallRecordIncomingSyncMessageManagerImpl!

    override func setUp() {
        mockCallRecordStore = MockCallRecordStore()
        mockIndividualCallRecordManager = MockIndividualCallRecordManager()
        mockInteractionStore = MockInteractionStore()
        mockMarkAsReadShims = MockMarkAsReadShims()
        mockRecipientStore = MockRecipientStore()
        mockThreadStore = MockThreadStore()

        incomingSyncMessageManager = CallRecordIncomingSyncMessageManagerImpl(
            callRecordStore: mockCallRecordStore,
            individualCallRecordManager: mockIndividualCallRecordManager,
            interactionStore: mockInteractionStore,
            markAsReadShims: mockMarkAsReadShims,
            recipientStore: mockRecipientStore,
            threadStore: mockThreadStore
        )
    }

    func testUpdatesIndividualCallIfExists() {
        let callId = UInt64.maxRandom
        let interactionRowId = Int64.maxRandom
        let threadRowId = Int64.maxRandom

        let callRecord = CallRecord(
            callId: callId,
            interactionRowId: interactionRowId,
            threadRowId: threadRowId,
            callType: .audioCall,
            callDirection: .outgoing,
            callStatus: .individual(.notAccepted)
        )

        let contactAddress = SignalServiceAddress.isolatedRandomForTesting()
        let contactServiceId = contactAddress.aci!

        let thread = TSContactThread(contactAddress: contactAddress)
        thread.updateRowId(threadRowId)

        let interaction = TSCall(
            callType: .outgoingMissed,
            offerType: .audio,
            thread: thread,
            sentAtTimestamp: UInt64.maxRandom
        )
        interaction.updateRowId(interactionRowId)

        mockCallRecordStore.callRecords.append(callRecord)
        mockThreadStore.threads.append(thread)
        mockInteractionStore.insertedInteractions.append(interaction)

        mockDB.write { tx in
            incomingSyncMessageManager.createOrUpdateRecordForIncomingSyncMessage(
                incomingSyncMessage: CallRecordIncomingSyncMessageParams(
                    callId: callId,
                    conversationParams: .oneToOne(
                        contactServiceId: contactServiceId,
                        individualCallStatus: .accepted,
                        individualCallInteractionType: .incomingAnsweredElsewhere
                    ),
                    callTimestamp: .maxRandom,
                    callType: .audioCall,
                    callDirection: .outgoing
                ),
                syncMessageTimestamp: .maxRandom,
                tx: tx
            )
        }

        XCTAssertEqual(
            (mockInteractionStore.insertedInteractions.first! as! TSCall).callType,
            .incomingAnsweredElsewhere
        )
        XCTAssertEqual(
            mockIndividualCallRecordManager.updatedRecords,
            [.individual(.accepted)]
        )
        XCTAssertTrue(mockMarkAsReadShims.hasMarkedAsRead)
    }

    func testCreatesIndividualCallIfNoneExists() {
        let callId = UInt64.maxRandom
        let contactAddress = SignalServiceAddress.isolatedRandomForTesting()
        let contactServiceId = contactAddress.aci!

        mockRecipientStore.recipients.append(SignalRecipient(aci: contactServiceId, pni: nil, phoneNumber: nil))
        mockThreadStore.threads.append(TSContactThread(contactAddress: contactAddress))

        mockDB.write { tx in
            incomingSyncMessageManager.createOrUpdateRecordForIncomingSyncMessage(
                incomingSyncMessage: CallRecordIncomingSyncMessageParams(
                    callId: callId,
                    conversationParams: .oneToOne(
                        contactServiceId: contactServiceId,
                        individualCallStatus: .accepted,
                        individualCallInteractionType: .incomingAnsweredElsewhere
                    ),
                    callTimestamp: .maxRandom,
                    callType: .audioCall,
                    callDirection: .outgoing
                ),
                syncMessageTimestamp: .maxRandom,
                tx: tx
            )
        }

        XCTAssertEqual(
            (mockInteractionStore.insertedInteractions.first! as! TSCall).callType,
            .incomingAnsweredElsewhere
        )
        XCTAssertEqual(
            mockIndividualCallRecordManager.createdRecords,
            [callId]
        )
        XCTAssertTrue(mockMarkAsReadShims.hasMarkedAsRead)
    }
}

// MARK: - Mocks

private func notImplemented() -> Never {
    owsFail("Not implemented!")
}

// MARK: MockIndividualCallRecordManager

private class MockIndividualCallRecordManager: IndividualCallRecordManager {
    var createdRecords = [UInt64]()
    var updatedRecords = [CallRecord.CallStatus]()

    func createRecordForInteraction(
        individualCallInteraction: TSCall,
        contactThread: TSContactThread,
        callId: UInt64,
        callType: CallRecord.CallType,
        callDirection: CallRecord.CallDirection,
        individualCallStatus: CallRecord.CallStatus.IndividualCallStatus,
        shouldSendSyncMessage: Bool,
        tx: DBWriteTransaction
    ) {
        createdRecords.append(callId)
    }

    func updateRecordForInteraction(
        individualCallInteraction: TSCall,
        contactThread: TSContactThread,
        existingCallRecord: CallRecord,
        newIndividualCallStatus: CallRecord.CallStatus.IndividualCallStatus,
        shouldSendSyncMessage: Bool,
        tx: DBWriteTransaction
    ) {
        updatedRecords.append(.individual(newIndividualCallStatus))
    }

    func updateInteractionTypeAndRecordIfExists(individualCallInteraction: TSCall, contactThread: TSContactThread, newCallInteractionType: RPRecentCallType, tx: SignalServiceKit.DBWriteTransaction) {
        notImplemented()
    }

    func createOrUpdateRecordForInteraction(individualCallInteraction: TSCall, contactThread: TSContactThread, callId: UInt64, tx: DBWriteTransaction) {
        notImplemented()
    }
}

// MARK: MarkAsReadShims

private class MockMarkAsReadShims: CallRecordIncomingSyncMessageManagerImpl.Shims.MarkAsRead {
    var hasMarkedAsRead = false

    func markThingsAsReadForIncomingSyncMessage(
        callInteraction: TSInteraction & OWSReadTracking,
        thread: TSThread,
        syncMessageTimestamp: UInt64,
        tx: DBWriteTransaction
    ) {
        hasMarkedAsRead = true
    }
}

// MARK: MockRecipientStore

private class MockRecipientStore: RecipientDataStore {
    var recipients = [SignalRecipient]()

    func fetchRecipient(serviceId: ServiceId, transaction: DBReadTransaction) -> SignalRecipient? {
        return recipients.first(where: { $0.aci == serviceId })
    }

    func fetchRecipient(phoneNumber: String, transaction: DBReadTransaction) -> SignalRecipient? {
        notImplemented()
    }
    func insertRecipient(_ signalRecipient: SignalRecipient, transaction: DBWriteTransaction) {
        notImplemented()
    }
    func updateRecipient(_ signalRecipient: SignalRecipient, transaction: DBWriteTransaction) {
        notImplemented()
    }
    func removeRecipient(_ signalRecipient: SignalRecipient, transaction: DBWriteTransaction) {
        notImplemented()
    }
}
