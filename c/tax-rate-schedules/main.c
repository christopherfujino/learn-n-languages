#include <stdio.h>
#include <stdlib.h> // For exit()

const int SCHEDULE_COUNT = 7; // count schedules[]
const double INCOME = 100000; // $100k
const double EXPECTED = 13580;

typedef struct LimitRate {
  double limit;
  double rate;
} LimitRate;

const LimitRate schedules[] = {
  { .limit = 622050.0, .rate = 0.37 },
  { .limit = 414701, .rate = 0.35},
  { .limit = 326600, .rate = 0.32},
  { .limit = 171050, .rate = 0.24},
  { .limit = 80250, .rate = 0.22},
  { .limit = 19750, .rate = 0.12},
  { .limit = 0, .rate = 0.1},
};

double tax(double income) {
  for (int i = 0; i < SCHEDULE_COUNT; i++) {
    LimitRate limitRate = schedules[i];
    if (income > limitRate.limit) {
      return (income - limitRate.limit) * limitRate.rate + tax(limitRate.limit);
    }
  }
  return 0.0;
}

void ensure(double actual, double expected) {
  if (actual != expected) {
    fprintf(stderr, "Expected $%f but got $%f!\n", expected, actual);
    exit(1);
  }
}

int main() {
  const double taxes = tax(INCOME);
  ensure(taxes, EXPECTED);
  printf("Tax on $%0.2f is $%0.2f.\n", INCOME, taxes);
  return 0;
}
