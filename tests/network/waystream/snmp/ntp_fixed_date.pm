#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
package ntp_fixed_date;

# Always use the same fixed date to test certificate validity

BEGIN {
   *CORE::GLOBAL::time = sub { 1765874853 };
}

1
