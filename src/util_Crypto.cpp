#include "util/Crypto.h"

#include <mbedtls/aes.h>
#include <string.h>

namespace crypto {

bool aes256_ctr_transform(
  const uint8_t key[32],
  uint16_t local,
  uint16_t peer,
  uint32_t nonce,
  uint32_t msgId,
  const uint8_t* input,
  size_t len,
  uint8_t* output
) {
  mbedtls_aes_context ctx;
  mbedtls_aes_init(&ctx);

  int res = mbedtls_aes_setkey_enc(&ctx, key, 256);
  if (res != 0) {
    mbedtls_aes_free(&ctx);
    return false;
  }

  uint8_t iv[16] = {0};
  memcpy(iv + 0, &nonce, sizeof(nonce));
  memcpy(iv + 4, &msgId, sizeof(msgId));
  memcpy(iv + 8, &local, sizeof(local));
  memcpy(iv + 10, &peer, sizeof(peer));

  size_t nc_off = 0;
  uint8_t stream_block[16] = {0};
  res = mbedtls_aes_crypt_ctr(&ctx, len, &nc_off, iv, stream_block, input, output);
  mbedtls_aes_free(&ctx);
  return res == 0;
}

} // namespace crypto

