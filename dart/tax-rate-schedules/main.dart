const double INCOME = 100000; // $100k
const double EXPECTED = 13580;

final Map<double, double> schedules = <double, double>{
  622050: 0.37,
  414701: 0.35,
  326600: 0.32,
  171050: 0.24,
  80250: 0.22,
  19750: 0.12,
  0: 0.1,
};

double tax(double income) {
  for (final MapEntry<double, double> entry in schedules.entries) {
    final double limit = entry.key;
    final double rate = entry.value;
    if (income > limit) {
      return (income - limit) * rate + tax(limit);
    }
  }
  return 0;
}

void ensure(double actual, double expected) {
  if (actual != expected) {
    throw Exception('Expected \$$expected but got \$$actual!');
  }
}

void main() {
  final double taxes = tax(INCOME);
  ensure(taxes, EXPECTED);
  print('Tax on \$$INCOME is \$$taxes');
}
