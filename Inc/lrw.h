/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __LRW_H
#define __LRW_H

/* Includes ------------------------------------------------------------------*/
#include <stdint.h>
#include "LoRaMac.h"
#include "main.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Exported macros -----------------------------------------------------------*/
#define LORAWAN_APP_PORT                            1
#define LRW_QUEUE_LEN                               3

/* Exported types ------------------------------------------------------------*/

/*
 * NOTES
 *        C compiler can reorder lines, and is unaware of asynchronous
 *        behaviour, thus theoretically:
 *
 *          msg->trigger_type = 1; msg->msg_type = 1;
 *
 *        may become:
 *
 *          msg->msg_type = 1; msg->trigger_type = 1;
 *
 *        And disregard locking scheme described in enqueueToSend
 *
 *        PS: On GCC it's supposed to prevent memory access merging and
 *        duplication. not actually sure if it prevents reorder against a
 *        non-volatile data access.
 */
struct LRW_Msg {
  uint8_t volatile msg_type;
  uint8_t len;
  uint8_t msg[12];
#if defined(STX)
  uint8_t trigger_type;
#endif
};

struct LRW_Handle {
  uint8_t retrans_left;
  uint8_t retrans_index;
  int8_t retrans_txp_prior;
  bool retrans_txp_override;
  bool retrans_txp_internal;
  struct LRW_Msg queue[LRW_QUEUE_LEN];
};



/* Exported constants --------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern TimerTime_t DutyCycleWaitTime;
extern struct LRW_Handle lrw;
/* Exported functions --------------------------------------------------------*/
void LRW_Init(void);
void LRW_Send(void);
int32_t LRW_HasActivity(void);
void LRW_FromDevCfg(void);
bool LRW_IsJoined(void);
bool LRW_IsBusy(void);
uint8_t LRW_FromTxPower(uint8_t txp);
void LRW_Join(void);
void LRW_Process(void);
void LRW_ToDevCfg(void);
int32_t LRW_HasQueue(void);


#ifdef __cplusplus
}
#endif
#endif /* __LRW_H */
