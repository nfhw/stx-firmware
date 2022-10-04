#include <string.h>
#include "task_mgr.h"
#include "hardware.h"

struct task tasks[TASK_MAX] = {0};
volatile uint32_t tasks_ticks = 0;

struct task *tasks_add(struct task t);
int tasks_has_pending(void);

struct task *tasks_add(struct task t) {
  uint8_t i = 0;

  do {
    if(tasks[i].when <= tasks_ticks) {
      tasks[i] = t;
      return tasks + i;
    }
  } while(++i % TASK_MAX != 0);

  DEBUG_MSG("Couldn't add task, no space left!\n");
  return NULL;
}

void tasks_del(struct task *t) {
  memset(t, 0, sizeof *t);
}

int tasks_has_pending(void) {
  for(size_t i = 0; i < TASK_MAX; i++) {
    if(tasks[i].when > tasks_ticks)
      return -1;
  }
  return 0;
}

volatile uint8_t processingRdyTasks = 0;
void HAL_LPTIM_AutoReloadMatchCallback(LPTIM_HandleTypeDef *hlptim1) {
  tasks_ticks++;
  if (processingRdyTasks) {
    DEBUG_MSG("Timer ticked before task processing done.\n");
  } else {
    // Heart of the scheduler code
    processingRdyTasks = 1;
    for (size_t i = 0; i < TASK_MAX; ++i) {
      if (tasks[i].when == tasks_ticks) { // Ready
        tasks[i].cb(tasks[i].arg); // execute task function
      }
    }
    processingRdyTasks = 0;
  }
}

#ifdef __EXAMPLE
struct blinker {
  uint16_t led;
  uint32_t when;
  uint32_t count;
};

int blinker_has_overlap(blinker* b);
int blinker_add(blinker* b);
void blinker_task(void* led);

void blinker_task(void* led) {
  if((0xFFFF & (uint32_t) led) == LED_1_Pin) {
    HAL_GPIO_TogglePin(LED_1_GPIO_Port, LED_1_Pin);
  } else {
    HAL_GPIO_TogglePin(LED_2_GPIO_Port, LED_2_Pin);
  }
}

int blinker_has_overlap(blinker* b) {
  int i;

  for(i = 0; i < TASK_MAX; i++) {
    if (tasks[i].arg == (void*) (0x0U | b->led) &&
        tasks[i].when >= b->when &&
        tasks[i].when < b->when + b->count * 2 &&
        tasks[i].cb == &blinker_task) {
      return -1;
    }
  }
  return 0;
}

int blinker_add(blinker* b) {
  task t;
  uint32_t i;

  if(b->when == tasks_ticks) {
    DEBUG_MSG("Schedule into future, not present!\n");
    return -1;
  }

  if (-1 == blinker_has_overlap(b)) {
    DEBUG_MSG("Scheduling a blink, while another is already in-progress.\n");
    return -1;
  }

  for(i = 0; i < b->count * 2; i++) {
    t.arg = (void*) (0x0U | b->led);
    t.when = b->when + 1 + i;
    t.cb = &blinker_task;
    if(tasks_add(t)) {
      return -1;
    }
  }
  return 0;
}

/* Examples */

/*
 * Shorthand for blinking a given `led` `count` times.
 *
 * Schedule task asynchronously. (main continues ahead, without waiting for blinking to finish)
 * Block until ongoing tasks are finished. (main waits, while previous blinking finishes)
 */
void blink(uint16_t led, uint32_t count) {
  blinker b;

  do {
    b.led = led;
    b.when = tasks_ticks + 1;
    b.count = count;
  } while(-1 == blinker_add(&b));
}

/*
 * Ditto, but lower level.
 */
void blink_ll(uint16_t led, uint32_t count) {
  task t;
  uint32_t i, when;

  // Block, until no overlapping tasks exist.
  for(i = 0; i < TASK_MAX; i++) {
    when = tasks_ticks + 1;  // TODO Prevent potential compiler optimization.
    if (tasks[i].arg == (void*) (0x0U | led) &&
        tasks[i].when >= when &&
        tasks[i].when < when + count * 2 &&
        tasks[i].cb == &blinker_task) {
      continue;
    }
  }

  // Schedule count*2 tasks
  for(i = 0; i < count * 2; i++) {
    t.arg = (void*) (0x0U | led);
    t.when = when + i;
    t.cb = &blinker_task;
    if(NULL == tasks_add(t)) {
      DEBUG_PRINTF("blink_ll() gave up scheduling a blink. %d\n", HAL_GetTick());
      return;
    }
  }

}
/*
 * Wait until both red/green leds are free. Then blink.
 * 8 tasks, to perform 4x red/green interleaved blinks.
 */
void blink_grgrgrgr() {
  blinker green, red;
  do {
    green.led = LED_1_Pin;
    green.when = tasks_ticks + 1;
    green.count = 4;
    red.led = LED_2_Pin;
    red.when = tasks_ticks + 2;
    red.count = 4;
  } while(-1 == blinker_has_overlap(&green) && -1 == blinker_has_overlap(&red));
  if(-1 == blinker_add(&green)) {
    DEBUG_MSG("Giving up on scheduling green blinker!\n");
  }
  if( -1 == blinker_add(&red)) {
    DEBUG_MSG("Giving up on scheduling red blinker!\n");
  }
}
#endif
