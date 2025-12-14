#pragma once
#include <stdint.h>
#include <stddef.h>

// Lightweight in-memory pairing/key store for milestone 2.
// Avoids dynamic allocation and keeps deterministic timing on the MCU.
class PairingStore {
public:
  static constexpr size_t kMaxPeers = 6;
  static constexpr size_t kKeyLen = 32;

  void setLocalAddress(uint16_t addr) { _local = addr; }

  bool hasKey(uint16_t peer) const;
  bool loadKey(uint16_t peer, uint8_t out[kKeyLen]) const;
  bool rememberKey(uint16_t peer, const uint8_t key[kKeyLen]);

  bool recordOutgoingRequest(uint16_t peer, uint32_t msgId, uint32_t nonce);
  bool resolvePendingRequest(uint16_t peer, uint32_t refMsgId, uint32_t acceptNonce, uint8_t outKey[kKeyLen]);

  // Derive and remember a key when we receive a pairing request.
  bool deriveFromRequest(uint16_t peer, uint32_t reqMsgId, uint32_t reqNonce, uint32_t acceptNonce, uint8_t outKey[kKeyLen]);

  // Replay tracking for SecureChat. Returns true if msgId is new and updates the window.
  bool checkReplayAndUpdate(uint16_t peer, uint32_t msgId);

private:
  struct PairEntry {
    bool inUse = false;
    uint16_t peer = 0;
    uint8_t key[kKeyLen] = {0};
    uint32_t lastMsgId = 0;
  };

  struct PendingPairReq {
    bool active = false;
    uint16_t peer = 0;
    uint32_t msgId = 0;
    uint32_t nonce = 0;
  };

  PairEntry _entries[kMaxPeers];
  PendingPairReq _pending[kMaxPeers];

  uint16_t _local = 0;

  bool findFreeSlot(size_t& idx);
  bool findPending(uint16_t peer, uint32_t msgId, size_t& idx) const;
  static void deriveKeyMaterial(uint16_t a, uint16_t b, uint32_t mixedNonce, uint8_t out[kKeyLen]);
};
