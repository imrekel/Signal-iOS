//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@class SDSAnyWriteTransaction;
@class SignalServiceAddress;

@interface OWSReaction : BaseModel

@property (nonatomic, readonly) NSString *uniqueMessageId;
@property (nonatomic, readonly) NSString *emoji;
@property (nonatomic, readonly) SignalServiceAddress *reactor;
@property (nonatomic, readonly) uint64_t sentAtTimestamp;
@property (nonatomic, readonly) uint64_t receivedAtTimestamp;
@property (nonatomic, readonly) BOOL read;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUniqueId:(NSString *)uniqueId NS_UNAVAILABLE;
- (instancetype)initWithGrdbId:(int64_t)grdbId uniqueId:(NSString *)uniqueId NS_UNAVAILABLE;

- (instancetype)initWithUniqueMessageId:(NSString *)uniqueMessageId emoji:(NSString *)emoji reactor:(SignalServiceAddress *)reactor sentAtTimestamp:(uint64_t)sentAtTimestamp receivedAtTimestamp:(uint64_t)receivedAtTimestamp NS_DESIGNATED_INITIALIZER;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
                           emoji:(NSString *)emoji
                     reactorE164:(nullable NSString *)reactorE164
                     reactorUUID:(nullable NSString *)reactorUUID
                            read:(BOOL)read
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                 sentAtTimestamp:(uint64_t)sentAtTimestamp
                 uniqueMessageId:(NSString *)uniqueMessageId
NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(grdbId:uniqueId:emoji:reactorE164:reactorUUID:read:receivedAtTimestamp:sentAtTimestamp:uniqueMessageId:));

// clang-format on

// --- CODE GENERATION MARKER

- (void)markAsReadWithTransaction:(SDSAnyWriteTransaction *)transaction NS_SWIFT_NAME(markAsRead(transaction:));

@end

NS_ASSUME_NONNULL_END
