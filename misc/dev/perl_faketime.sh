#!/bin/bash
#
# Copyright 2025 ABillS
# ABillS Util for fake time settings
# Description:
#   Wrapper to run Perl scripts with a forced fake system time using libfaketime.
#   Usage example:
#     Change script shebang from:
#       #!/usr/bin/perl
#     to:
#       #!/usr/abills/misc/dev/perl_faketime
#
#   Required installation of library
#   `apt install faketime`
# Created: 2025-11-27


# Change date for your own purposes
DATE="2025-11-18"
TIME="10:00:21"

export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1
export FAKETIME="${DATE} ${TIME}"
exec /usr/bin/perl "$@"
