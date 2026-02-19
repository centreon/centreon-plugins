package fixed_date;

# Always use the same fixed date to test certificate validity
# Feb 19, 2026 00:00:00 UTC = 1771459200

BEGIN {
   *CORE::GLOBAL::time = sub { 1771459200 };
}

1
