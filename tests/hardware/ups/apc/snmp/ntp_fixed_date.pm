package ntp_fixed_date;

# Always use the same fixed date to test certificate validity

BEGIN {
   *CORE::GLOBAL::time = sub { 1756165823 };
}

1
