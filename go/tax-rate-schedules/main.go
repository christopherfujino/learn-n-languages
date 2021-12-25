package main

import (
  "fmt"
)

const INCOME float32 = 100000; // $100k
const EXPECTED_TAXES float32 = 13580;

type schedule struct {
  limit float32
  rate float32
}

// this cannot be map because maps cannot be iterated over in a stable order
var SCHEDULES = []schedule{
  {limit: 622050, rate: 0.37},
  {limit: 414701, rate: 0.35},
  {limit: 326600, rate: 0.32},
  {limit: 171050, rate: 0.24},
  {limit: 80250, rate: 0.22},
  {limit: 19750, rate: 0.12},
  {limit: 0, rate: 0.1},
}

func main() {
  taxes := tax(INCOME)
  ensure(taxes, EXPECTED_TAXES)
  fmt.Printf("Tax on $%0.2f is $%0.2f.\n", INCOME, taxes)
}

func ensure(actual float32, expected float32) {
  if (actual != expected) {
    panic(
      fmt.Sprintf("Expected $%f but got $%f!\n", expected, actual),
    )
  }
}

func tax(income float32) float32 {
  for _, schedule := range SCHEDULES {
    if income > schedule.limit {
      return (income - schedule.limit) * schedule.rate + tax(schedule.limit)
    }
  }
  return 0
}
