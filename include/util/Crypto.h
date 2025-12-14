#pragma once
#include <stddef.h>
#include <stdint.h>

namespace crypto {

// AES-256 CTR transform. Input and output may alias.
bool aes256_ctr_transform(
  const uint8_t key[32],
  uint16_t local,
  uint16_t peer,
  uint32_t nonce,
  uint32_t msgId,
  const uint8_t* input,
  size_t len,
  uint8_t* output
);

}

