#ifndef __isr_H
#define __isr_H
#ifdef __cplusplus
extern "C" {
#endif

/* Exported functions ------------------------------------------------------- */
void ButtonISR(void);
void NFCISR(void);
void ReedSwitchISR(void);

#ifdef __cplusplus
}
#endif
#endif /*__ isr_H */
