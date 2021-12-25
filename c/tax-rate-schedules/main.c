#include <stdio.h>

typedef struct LimitRate {
  double limit;
  double rate;
} LimitRate;

LimitRate schedule_one = {
  .limit = 622050.0,
  .rate = 0.37,
};

int main() {
  return 0;
}
