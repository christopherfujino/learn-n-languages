class Test {
  public static void main(String[] args) {
    double taxOwed = tax(INCOME);
    System.out.printf("Tax on $%.2f is $%.2f\n", INCOME, taxOwed);
  }

  static double tax(double income) {
    for (Schedule schedule : SCHEDULES) {
      if (income > schedule.limit) {
        return (income - schedule.limit) * schedule.rate + tax(schedule.limit);
      }
    }
    return 0.0;
  }

  static final double INCOME = 100000; // $100k
  static final double EXPECTED_TAXES = 13580;
  static final Schedule[] SCHEDULES = {
    new Schedule(622050.0, 0.37),
    new Schedule(414701.0, 0.35),
    new Schedule(326600.0, 0.32),
    new Schedule(171050.0, 0.24),
    new Schedule(80250.0, 0.22),
    new Schedule(19750.0, 0.12),
    new Schedule(0.0, 0.1),
  };
};

class Schedule {
  Schedule(double l, double r) {
    limit = l;
    rate = r;
  }

  double limit;
  double rate;
}
