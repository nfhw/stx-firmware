#ifndef __TASK_MGR
#define __TASK_MGR

#include "stm32l0xx_hal.h"
#include "stm32l071xx.h"


#ifdef __cplusplus
extern "C" {
#endif

/* types     ------------------------------- */

/*
 * Scheduler
 * The LPTIM can Wake Up the device from *Stop Mode*.
 *
 * task.when:    Each unit is ~100ms. Time at which to perform the task.
 * task.arg:     User defined. A machine word, that's passed as argument to the task.
 *               Can be either a pointer to a struct, or simply a value.
 * task.cb:      User defined. Task callback itself that returns nothing.
 *
 * tasks_ticks:  Users read only. Seconds precision. LPTIM Handler execution counter.
 * Timer_count:  Frequency of scheduler invocation. 256 is 1s. Thus 26 is ~100ms.
 *
 */
struct task {
  uint32_t when;
  void *arg;
  void (*cb)(void *arg);
};

/* constants ------------------------------- */

/* Define how many tasks the scheduler can hold at a point in time */
#define TASK_MAX 20
/* Scheduler Frequency. One second is 256, thus 26 is ~0.1 second (assuming current LPTIM configurations)
 * Value loaded into 0x4000_7c18 0x0000_ffff | rw | LPTIM_ARR (autoreload register).ARR
 *
 * Every time LPTIM_CNT Reaches this number. LPTIM IRQ happens. Triggering our scheduler.
 */
#define TIMER_COUNT 26

/* globals --------------------------------- */

extern struct task tasks[TASK_MAX];
extern volatile uint32_t tasks_ticks;

/* functions ------------------------------- */

struct task *tasks_add(struct task t);
void tasks_del(struct task *t);
int tasks_has_pending(void);

#ifdef __cplusplus
}
#endif
#endif // __TASK_MGR
