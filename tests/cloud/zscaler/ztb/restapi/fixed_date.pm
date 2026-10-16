package fixed_date;

# Copyright 2026-Present Centreon
# Always use the same fixed date to get constant durations

BEGIN {
   *CORE::GLOBAL::time = sub { 1783674000 };
}

1
