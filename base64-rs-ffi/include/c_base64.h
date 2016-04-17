/*
* Copyright (C) 2013 Etherios, All Rights Reserved
*
* This software contains proprietary and confidential information of Etherios.
* By accepting transfer of this copy, Recipient agrees to retain this software
* in confidence, to prevent disclosure to others, and to make no use of this
* software other than that for which it was delivered. This is a published
* copyrighted work of Etherios. Except as permitted by federal law, 17 USC 117,
* copying is strictly prohibited.
*
* Restricted Rights Legend
*
* Use, duplication, or disclosure by the Government is subject to restrictions
* set forth in sub-paragraph (c)(1)(ii) of The Rights in Technical Data and
* Computer Software clause at DFARS 252.227-7031 or subparagraphs (c)(1) and
* (2) of the Commercial Computer Software - Restricted Rights at 48 CFR
* 52.227-19, as applicable.
*/


/** @file
*	@brief
*	    Base64 encoding and decoding as specified in RFC 3548
*       Standard alphabet
*	@section License
*	    (C) Copyright 2013 Etherios
*/
#ifndef __C_BASE64_H__
#define __C_BASE64_H__

#include <stdint.h>
#include <stddef.h>

/** @brief Increases on non backwards-compatible changes to the external API. */
#define C_BASE64_VERSION_MAJOR 1
/** @brief Increases on backwards-compatible large additions to the external API or major internal changes. */
#define C_BASE64_VERSION_MINOR 1
/** @brief Increases on backwards-compatible bug fixes or small additions to the external API. */
#define C_BASE64_VERSION_BUILD 0

/** @brief Maximum size of encoded data */
#define C_BASE64_ENCODE_SIZER(unencodedSize) (((size_t)((unencodedSize + 2) / 3.0)) * 4 + 1)

/** @brief Maximum size of decoded data. Valid when encodedSize is a multiple of 4. */
#define C_BASE64_DECODE_SIZER(encodedSize) ((size_t)((encodedSize / 4) * 3))

/** @brief
*       Encode binary data into a base64 ASCII string
*   @param[out] dst
*       Memory block to populate with encoded string
*   @param[in] dstSize
*       Size of allocated memory at \e dst
*   @param[in] src
*       Binary data to encode
*   @param[in] srcLength
*       Number of bytes of \e src data
*   @return
*       Number of characters that were copied to dst
*       Will be zero if an error occurred
*/
extern size_t c_base64_encode(char * const dst, size_t const dstSize, uint8_t const * const src, size_t const srcLength);

/** @brief
*       Decode a base64 encoded ASCII string
*   @param[out] dst
*       Memory block to populate with decoded binary data
*       Allowed to be the same address as src for an in-place operation
*   @param[in] dstSize
*       Size of allocated memory at \e dst
*   @param[in] src
*       NUL terminated base64 encoded ASCII string
*   @return
*       Number of bytes that were copied to dst
*       Will be zero if an error occurred
*/
extern size_t c_base64_decode(uint8_t * const dst, size_t const dstSize, char const * const src);


#endif
