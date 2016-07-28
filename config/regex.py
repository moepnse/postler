#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re


"""
================================================================================
Sample Configuration:
================================================================================
if X-Spam == YES {
   create dir = True
   folder = Spam
}

if X-Virus == YES {
   create dir = True
   folder = Virus
}

if From == regex([\w]*@ams.at) {
   create dir = True
   folder = AMS
}

================================================================================
Samples:
================================================================================
if X-Spam == YES {
   create dir = True
   folder = Spam
}

if From == regex([\w]*@ams.at) {
   create dir = True
   folder = AMS
}

================================================================================
Sample 1:
================================================================================
if[\w\s\-]*==[\w\s\-\.\@\(\)\*_\[\]\{\}\\\]*\{[\w\s\n=]*\}
if X-Spam == YES {
   create dir = True
   folder = Spam
}

(?<=\if)[\w\s\-\.\@\(\)\*_\[\]=\\\]*(?=\{)
X-Spam == YES

(?<=\{)[\w\s\n=]*(?=\})
create dir = True
folder = Spam

================================================================================
Sample 2:
================================================================================
if[\w\s\-]*==[\w\s\-\.\@\(\)\*_\[\]\{\}\\\]*\{[\w\s\n=]*\}
if From == regex([\w]*@ams.at) {
   create dir = True
   folder = AMS
}

(?<=\if)[\w\s\-\.\@\(\)\*_\[\]=\\\]*(?=\{)
From == regex([\w]*@ams.at)

(?<=\{)[\w\s\n=]*(?=\})
create dir = True
folder = AMS

(?<=regex\()[\w\s\-\.\@\*_\[\]\{\}=\\\]*(?=\))
[\w]*@ams.at

"""

class Condition(object):
    def __init__(self, condition, regex):

        self._condition = condition
        self._regex = regex

        self.folder = None
        self.create_dir = True
        self.field = None
        self.value = None
        self.value_is_regex = False

    def parse(self):
        if_instruction = self._regex[0].findall(condition)[0]

        tmp = if_instruction.split("==")
        self.field = tmp[0].strip()
        self.value = tmp[1].strip()

        if self._value.startswith("regex"):
            self.r = re.compile(self._regex[2].findall(self.value)[0])
            self.value_is_regex = True

        for group in self._regex[1].findall(condition):

            tmp2 = group.split("\n")
            for line in tmp2:
                if "=" in line:
                    tmp3 = line.split("=")
                    tmp3[0] = tmp3[0].strip().lower()
                    tmp3[1] = tmp3[1].strip().lower()

                    if tmp3[0] == "folder":
                        self.folder = tmp3[1]
                    elif tmp3[0] == "create dir":
                        if tmp[1] == "true":
                            self.create_dir = True
                        elif tmp[1] == "false":
                            self.create_dir = False

    def check(self, email_message):
        tag = email_message.__getitem__(tmp[0])
        if tag != None:
            if self.value_is_regex == True:
                if self.r.match(tag):
                    return True
            else:
                if tag == tmp[1]:
                    return True
        return False


class ConfigParser(object):
    def __init__(self, config):
        self.config = config
        self.conditions = []

    def compile_regex(self):
        #self._r = re.compile("if[\w\W]*==[\w\W]*\{[\w\W]*\}")
        #self._r2 = re.compile("(?<=\if)[\w\W]*(?=\{)")
        #self._r3 = re.compile("(?<=\{)[\w\W\n=]*(?=\})")
        #self._r4 = re.compile("(?<=regex\()[\w\W]*(?=\))")

        self._r = re.compile("if[\w\s\-]*==[\w\s\-\.\@\(\)\*_\[\]\{\}\\\]*\{[\w\s\n=]*\}")
        self._r2 = re.compile("(?<=\if)[\w\s\-\.\@\(\)\*_\[\]=\\\]*(?=\{)")
        self._r3 = re.compile("(?<=\{)[\w\s\n=]*(?=\})")
        self._r4 = re.compile("(?<=regex\()[\w\s\-\.\@\*_\[\]\{\}=\\\]*(?=\))")

        #self._r = re.compile("if[\w\s\W]*==[\w\s\W]*\{[\w\s\n\W]*\}")
        #self._r2 = re.compile("(?<=\if)[\w\s\W]*(?=\{)")
        #self._r3 = re.compile("(?<=\{)[\w\s\n=]*(?=\})")
        #self._r4 = re.compile("(?<=regex\()[\w\s\W]*(?=\))")

        self._regex = [self._r2, self._r3, self._r4]

    def parse_conditions(self):
        for group in self._r.findall(self._config):
            current_condition = Condition(group, self._regex)
            current_condition.parse()
            self.conditions.append(current_condition)