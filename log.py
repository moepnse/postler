#! /usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import time

STD_OUT = 1
STD_ERR = 2

def log(msg, channel=STD_OUT):
    date = time.strftime("[%d-%m-%Y %H:%M:%S]", time.gmtime())
    if channel != STD_ERR:
        sys.stdout.write("%s %s\n" % (date, msg))
    else:
        sys.stderr.write("%s %s\n" % (date, msg))