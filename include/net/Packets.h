#pragma once
#include <stdint.h>

// Wire format for direct messages and delivery receipts.
// Keep it small: large payloads increase airtime and collision probability.
//
// Milestone 2 adds pairing, presence, and encrypted payload support. SecureChat
// packets carry ciphertext in `text` along with a nonce for AES-256-CTR.
enum class PacketKind : uint8_t {
  Chat = 0,
  Ack = 1,
  Discovery = 2,
  Presence = 3,
  PairRequest = 4,
  PairAccept = 5,
  SecureChat = 6
};

struct WireChatPacket {
  PacketKind kind;       // Chat or Ack
  uint32_t msgId;        // Sender-generated id (monotonic or random)
  uint16_t to;           // Destination node
  uint16_t from;         // Source node (optional; can be overwritten by receiver metadata)
  uint32_t ts;           // Unix time if available, else millis()/1000
  uint32_t refMsgId;     // For Ack: original chat msgId; for Chat: 0
  uint32_t nonce;        // For SecureChat/Pairing: AES nonce or pairing nonce
  uint16_t textLen;      // Length of valid bytes in text (ciphertext or presence info)
  uint16_t reserved;     // Reserved for future use; keeps alignment deterministic
  char text[80];         // Null-terminated UTF-8 subset (ASCII recommended for now)
};
