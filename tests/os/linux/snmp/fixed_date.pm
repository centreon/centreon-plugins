package fixed_date;

# Copyright 2026-Present Centreon
# Always use the same fixed date to test certificate validity

BEGIN {
   *CORE::GLOBAL::time = sub { 1723538393 };
}

1
