#include "storage/Pairing.h"

#include <Arduino.h>
#include <string.h>

namespace {
struct PersistedPairEntry {
  uint8_t inUse;
  uint16_t peer;
  uint32_t lastMsgId;
  uint8_t key[PairingStore::kKeyLen];
};
}

bool PairingStore::begin() {
  if (_prefs.begin("alora_pair", false)) {
    loadPersisted();
    return true;
  }
  return false;
}

bool PairingStore::hasKey(uint16_t peer) const {
  for (size_t i = 0; i < kMaxPeers; i++) {
    if (_entries[i].inUse && _entries[i].peer == peer) return true;
  }
  return false;
}

bool PairingStore::loadKey(uint16_t peer, uint8_t out[kKeyLen]) const {
  for (size_t i = 0; i < kMaxPeers; i++) {
    if (!_entries[i].inUse || _entries[i].peer != peer) continue;
    memcpy(out, _entries[i].key, kKeyLen);
    return true;
  }
  return false;
}

bool PairingStore::rememberKey(uint16_t peer, const uint8_t key[kKeyLen]) {
  for (size_t i = 0; i < kMaxPeers; i++) {
    if (_entries[i].inUse && _entries[i].peer == peer) {
      memcpy(_entries[i].key, key, kKeyLen);
      return persistEntry(i);
    }
  }

  size_t idx = 0;
  if (!findFreeSlot(idx)) return false;
  PairEntry& e = _entries[idx];
  e.inUse = true;
  e.peer = peer;
  memcpy(e.key, key, kKeyLen);
  e.lastMsgId = 0;
  return persistEntry(idx);
}

bool PairingStore::recordOutgoingRequest(uint16_t peer, uint32_t msgId, uint32_t nonce) {
  for (size_t i = 0; i < kMaxPeers; i++) {
    PendingPairReq& slot = _pending[i];
    if (slot.active && slot.peer == peer) {
      slot.msgId = msgId;
      slot.nonce = nonce;
      return true;
    }
  }

  for (size_t i = 0; i < kMaxPeers; i++) {
    PendingPairReq& slot = _pending[i];
    if (slot.active) continue;
    slot.active = true;
    slot.peer = peer;
    slot.msgId = msgId;
    slot.nonce = nonce;
    return true;
  }
  return false;
}

bool PairingStore::resolvePendingRequest(uint16_t peer, uint32_t refMsgId, uint32_t acceptNonce, uint8_t outKey[kKeyLen]) {
  size_t idx = 0;
  if (!findPending(peer, refMsgId, idx)) return false;
  PendingPairReq& slot = _pending[idx];
  uint32_t mixed = slot.nonce ^ acceptNonce;
  uint16_t lo = (_local < peer) ? _local : peer;
  uint16_t hi = (_local < peer) ? peer : _local;
  deriveKeyMaterial(lo, hi, mixed, outKey);
  slot.active = false;
  return rememberKey(peer, outKey);
}

bool PairingStore::deriveFromRequest(uint16_t peer, uint32_t reqMsgId, uint32_t reqNonce, uint32_t acceptNonce, uint8_t outKey[kKeyLen]) {
  (void)reqMsgId;
  uint32_t mixed = reqNonce ^ acceptNonce;
  uint16_t lo = (_local < peer) ? _local : peer;
  uint16_t hi = (_local < peer) ? peer : _local;
  deriveKeyMaterial(lo, hi, mixed, outKey);
  return rememberKey(peer, outKey);
}

bool PairingStore::checkReplayAndUpdate(uint16_t peer, uint32_t msgId) {
  for (size_t i = 0; i < kMaxPeers; i++) {
    PairEntry& e = _entries[i];
    if (!e.inUse || e.peer != peer) continue;
    if (msgId <= e.lastMsgId) return false;
    e.lastMsgId = msgId;
    return persistEntry(i);
  }
  return false;
}

bool PairingStore::findFreeSlot(size_t& idx) {
  for (size_t i = 0; i < kMaxPeers; i++) {
    if (!_entries[i].inUse) { idx = i; return true; }
  }
  return false;
}

bool PairingStore::findPending(uint16_t peer, uint32_t msgId, size_t& idx) const {
  for (size_t i = 0; i < kMaxPeers; i++) {
    if (!_pending[i].active) continue;
    if (_pending[i].peer != peer) continue;
    if (_pending[i].msgId != msgId) continue;
    idx = i;
    return true;
  }
  return false;
}

void PairingStore::deriveKeyMaterial(uint16_t a, uint16_t b, uint32_t mixedNonce, uint8_t out[kKeyLen]) {
  // Deterministic, allocation-free mixing inspired by splitmix64.
  uint64_t state = 0x9E3779B97F4A7C15ULL;
  state ^= ((uint64_t)a << 16) | (uint64_t)b;
  state ^= ((uint64_t)mixedNonce << 1);

  for (size_t i = 0; i < kKeyLen; i += 8) {
    state += 0x9E3779B97F4A7C15ULL;
    uint64_t z = state;
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    z = z ^ (z >> 31);
    memcpy(out + i, &z, 8);
  }
}

bool PairingStore::persistEntry(size_t idx) {
  if (idx >= kMaxPeers) return false;
  PersistedPairEntry blob{};
  blob.inUse = _entries[idx].inUse ? 1 : 0;
  blob.peer = _entries[idx].peer;
  blob.lastMsgId = _entries[idx].lastMsgId;
  memcpy(blob.key, _entries[idx].key, kKeyLen);

  char key[8];
  snprintf(key, sizeof(key), "p%u", (unsigned)idx);

  size_t written = _prefs.putBytes(key, &blob, sizeof(blob));
  _lastPersistMs = (uint32_t)millis();
  return written == sizeof(blob);
}

void PairingStore::loadPersisted() {
  for (size_t i = 0; i < kMaxPeers; i++) {
    char key[8];
    snprintf(key, sizeof(key), "p%u", (unsigned)i);

    PersistedPairEntry blob{};
    size_t got = _prefs.getBytes(key, &blob, sizeof(blob));
    if (got != sizeof(blob)) continue;
    if (!blob.inUse) continue;

    _entries[i].inUse = true;
    _entries[i].peer = blob.peer;
    _entries[i].lastMsgId = blob.lastMsgId;
    memcpy(_entries[i].key, blob.key, kKeyLen);
  }
}
