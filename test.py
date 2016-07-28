#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import socket

import postler


class SelfTest(object):

    def self_test(self):

        username = self._username
        domain = socket.gethostname()

        path = "%s %s%s %s%s" % (os.path.abspath( __file__ ), "--maildir=", self._maildir, "--username=", self._username)
        print path


        message1 = """Subject: [SPAM] Postler Test
From: postler@%s
To: %s@%s
X-Spam: YES

Dies ist eine automatisch generierte Test E-Mail von Postler
""" % (socket.gethostname() username, domain)

        fd = os.popen(path, "w")
        fd.write(message1)
        fd.close()

        message2 = """Subject: [VIRUS] Postler Test
From: postler@%s
To: %s@%s
X-Virus: YES

Dies ist eine automatisch generierte Test E-Mail von Postler
""" % (socket.gethostname(), username, domain)

        fd = os.popen(path, "w")
        fd.write(message2)
        fd.close()

        message3 = """Subject: [NORMAL] Postler Test
From: postler@%s
To: %s@%s

Dies ist eine automatisch generierte Test E-Mail von Postler
""" % (socket.gethostname(), username, domain)
        fd = os.popen(path, "w")
        fd.write(message3)
        fd.close()


class Postler(postler.Postler, SelfTest):
    def __init__(self, config, maildir, username, self_test=False):

        postler.Postler.__init__(self, config, maildir, username)

        if self_test == True:
            self.self_test()
        else:
            self.get_mail()