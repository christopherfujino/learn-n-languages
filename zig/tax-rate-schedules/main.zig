const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

const LimitRate = struct {
    limit: f32,
    rate: f32,
};

const schedule = [_]LimitRate{
    .{ .limit = 622050, .rate = 0.37 },
    .{ .limit = 414701, .rate = 0.35 },
    .{ .limit = 326600, .rate = 0.32 },
    .{ .limit = 171050, .rate = 0.24 },
    .{ .limit = 80250, .rate = 0.22 },
    .{ .limit = 19750, .rate = 0.12 },
    .{ .limit = 0, .rate = 0.1 },
};

fn tax(income: f32) f32 {
    for (schedule) |limitRate| {
        if (income > limitRate.limit) {
            return (income - limitRate.limit) * limitRate.rate + tax(limitRate.limit);
        }
    }
    return 0;
}

pub fn main() !void {
    print("Hello, {s}!\n", .{"world"});
}

test "$100k -> $13,580" {
    const income: f32 = 100000;
    const taxes = tax(income);
    try expect(taxes == 13580);
}
