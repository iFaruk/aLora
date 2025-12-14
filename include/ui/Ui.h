#pragma once
#include <stdint.h>

#include "display/Display.h"
#include "input/Rotary.h"
#include "net/MeshRadio.h"
#include "storage/ChatLog.h"
#include "storage/Pairing.h"

class Ui {
public:
  Ui(IDisplay* display, RotaryInput* input, MeshRadio* radio, ChatLog* log, PairingStore* pairs);

  void begin();
  void tick();

  // Called from radio RX callback
  void onIncoming(uint16_t src, const WireChatPacket& pkt);

private:
  enum class Screen : uint8_t { Chat=0, Compose=1, Status=2, Settings=3 };
  enum class ComposeFocus : uint8_t { Destination=0, Cursor=1, Character=2, Send=3 };

  IDisplay* _d = nullptr;
  RotaryInput* _in = nullptr;
  MeshRadio* _radio = nullptr;
  ChatLog* _log = nullptr;
  PairingStore* _pairs = nullptr;

  struct PendingSend {
    bool active = false;
    uint16_t dst = 0;
    uint8_t attempts = 0;
    bool discoverySent = false;
    uint32_t lastSendMs = 0;
    uint32_t nextSendMs = 0;
    WireChatPacket pkt{};
  };

  static constexpr size_t kMaxPending = 4;
  PendingSend _pending[kMaxPending];

  Screen _screen = Screen::Chat;
  uint32_t _lastDrawMs = 0;
  uint32_t _lastPresenceMs = 0;

  // Chat scroll
  int32_t _chatScroll = 0;

  // Compose state
  uint16_t _dst = 1;
  char _draft[25] = {0};
  uint8_t _cursor = 0;
  uint8_t _charIndex = 0;
  ComposeFocus _focus = ComposeFocus::Destination;
  uint32_t _nextMsgId = 1;

  void drawChat();
  void drawCompose();
  void drawStatus();
  void drawSettings();

  void sendAck(uint16_t dst, uint32_t refMsgId);

  void handleInput();
  void handleClick();
  void handleDelta(int32_t delta);
  void handleComposeClick();
  void handleComposeDelta(int32_t delta);
  void advanceCursor(int32_t delta);
  void syncCharIndexToDraft();
  void sendDraft();
  void sendSecureDraft();
  void sendPairRequest(uint16_t dst);
  void sendPairAccept(uint16_t dst, const WireChatPacket& req, uint32_t acceptNonce);
  void notePairing(uint16_t peer, const char* msg);
  void recordPending(const WireChatPacket& pkt);
  void updateReliability();
  void escalateDiscovery(PendingSend& slot, uint32_t now);
  void clearPending(uint32_t msgId);
  uint32_t computeRetryDelayMs(uint8_t attempt) const;
  size_t pendingCount() const;
  void maybeBroadcastPresence(uint32_t now);
  void handlePresence(uint16_t src, const WireChatPacket& pkt);
  void handlePairRequest(uint16_t src, const WireChatPacket& pkt);
  void handlePairAccept(uint16_t src, const WireChatPacket& pkt);
  void handleSecureChat(uint16_t src, const WireChatPacket& pkt);
  bool decryptSecureText(uint16_t src, const WireChatPacket& pkt, char* outText, size_t outLen);
  bool ensurePairedOrRequest(uint16_t dst);
  uint32_t nextNonce() const;
};
