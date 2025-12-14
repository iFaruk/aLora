#pragma once
#include <stdint.h>
#include <stddef.h>
#include "net/Packets.h"
#include "net/Dedupe.h"

// Thin wrapper around LoRaMesher.
// Responsibilities:
// - Configure LoRaMesher pins + radio parameters from AppBuildConfig.
// - Provide a single RX callback delivering decoded WireChatPacket.
// - Provide a DM send primitive (currently uses LoRaMesher reliable send).
class MeshRadio {
public:
  using RxCallback = void (*)(uint16_t src, const WireChatPacket& pkt, int16_t rssi, float snr);

  bool begin();
  void setRxCallback(RxCallback cb);

  bool sendDm(uint16_t dst, const WireChatPacket& pkt);
  bool sendDiscovery(uint16_t target, uint32_t refMsgId);

  // Airtime discipline helpers for the UI/status page.
  uint32_t airtimeWindowUsedMs() const { return _airtimeUsedInWindow; }
  uint32_t airtimeWindowBudgetMs() const { return kAirtimeBudgetMs; }
  uint32_t msUntilAirtimeReset(uint32_t nowMs) const;

  uint16_t localAddress() const;

  uint32_t rxCount() const { return _rxCount; }
  uint32_t txCount() const { return _txCount; }
  uint32_t txAirtimeMs() const { return _txAirtimeMs; }

private:
  static void processReceivedPackets(void* pv);

  void onRxPacket(uint16_t src, const WireChatPacket& pkt, int16_t rssi, float snr);
  void sendAck(uint16_t dst, uint32_t refMsgId);
  uint32_t estimateTimeOnAirMs(size_t payloadBytes) const;

  void* _rxTaskHandle = nullptr; // TaskHandle_t (kept void* to avoid extra includes in header)
  volatile uint32_t _rxCount = 0;
  volatile uint32_t _txCount = 0;
  volatile uint32_t _txAirtimeMs = 0;
  RxCallback _rxCb = nullptr;
  mutable DedupeCache _dedupe;
  uint32_t _msgSeq = 1;

  static constexpr uint32_t kAirtimeBudgetMs = 1400;   // per rolling window
  static constexpr uint32_t kAirtimeWindowMs = 60000;  // window duration
  uint32_t _airtimeWindowStartMs = 0;
  uint32_t _airtimeUsedInWindow = 0;

  bool reserveAirtime(size_t payloadBytes, bool critical);
};
