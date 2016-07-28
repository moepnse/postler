# -*- coding: utf-8 -*-


import os
import re
import sys
import pwd
import email
import socket
import getopt
import mailbox

import config.tps as tps
import config.lua as lua
from log import *


class FolderCreationDenied(Exception):
    def __init__(self, folder):
        self.folder = folder

    def __str__(self):
        return repr(self.folder)


class Postler():
    def __init__(self, config, maildir, username):

        self._config = config
        self._maildir = maildir
        self._username = username

        #self._parser = regex.ConfigParser(self._config)
        if self._config.endswith(".tps"):
            self._parser = tps.get_parser(self._config)
        elif self._config.endswith(".lua"):
            self._parser = lua.get_parser(self._config)
        else:
            pass

    def get_folder(self, maildir_folder, path, create_folder=True, message_id=None):
        folders = []
        for folder in path.split("/"):
            try:
                maildir_folder = maildir_folder.get_folder(folder)
                folders.append(folder)
            except mailbox.NoSuchMailboxError:
                if create_folder:
                    log("[%s] Folder %s does not exist" % (message_id, folder), STD_OUT)
                    log("[%s] Creating dir %s" % (message_id, folder), STD_OUT)
                    maildir_folder = maildir_folder.add_folder(folder)
                else:
                    raise FolderCreationDenied("/".join(folders))
        return maildir_folder

    def create_folder(self, maildir_folder, path, message_id=None):
        folders = []
        for folder in path.split("/"):
            try:
                maildir_folder = maildir_folder.get_folder(folder)
                folders.append(folder)
                log("[%s] folder %s already exists" % (message_id, "/".join(folders)), STD_OUT)
            except mailbox.NoSuchMailboxError:
                log("[%s] Folder %s does not exist" % (message_id, folder), STD_OUT)
                log("[%s] Creating dir %s" % (message_id, folder), STD_OUT)
                maildir_folder = maildir_folder.add_folder(folder)
        return maildir_folder

    def clean_up(self):
        try:
            maildir = mailbox.Maildir(self._maildir, None, True)
            for key, email_message in maildir.items():
                message_id = email_message.__getitem__("Message-Id")
                subject = email_message.__getitem__("Subject")
                self._parser.parse(email_message)
                #print self._parser._variables
                if "folder" in self._parser and self._parser['folder'] is not None:
                    folder = self._parser["folder"]
                    create_dir = self._parser["create dir"]
                    log("[%s] Moving mail to folder %s" % (message_id, folder), STD_OUT)
                    try:
                        maildir_folder = self.get_folder(maildir, folder, create_dir, message_id)
                        maildir_folder.add(email_message)
                    except FolderCreationDenied:
                        log("[%s] Creation of folder %s is denied" % (message_id, folder), STD_OUT)
                        log("[%s] Ignoring message" % (message_id), STD_OUT)
                        continue
                    log("[%s] Removing message" % (message_id), STD_OUT)
                    maildir.remove(key)
        except StandardError, err:
            log("Programm Error: %s" % (err), STD_ERR)

    def get_mail(self):

        message = ""

        while 1:
            line = sys.stdin.read()
            if not line:
                break
            message += line

        #print message
        self.check_mail(message)

    def check_folders(self):
        folders = ["new", "tmp", "cur"]
        for folder in folders:
            path = os.path.join(self._maildir, folder)
            if not os.path.isdir(path):
                if not os.access(self._maildir, os.W_OK):
                    log("Can not write in: \"%s\"" % (path), STD_ERR)
                else:
                    log("Dir not found: \"%s\"" % (path), STD_ERR)
                    os.mkdir(path)

    def check_mail(self, message):

        self.check_folders()

        maildir = mailbox.Maildir(self._maildir, None, True)
        #maildir.get_folder(folder)

        try:
            email_message = email.message_from_string(message)
            message_id = email_message.__getitem__("Message-Id")
            subject = email_message.__getitem__("Subject")

            log("[%s] Got new e-mail for user \"%s\" with subject \"%s\"" % (message_id, self._username, subject), STD_OUT)

            self._parser.parse(email_message)
            if "folder" in self._parser and self._parser['folder'] is not None:
                folder = self._parser["folder"]
                create_dir = self._parser["create dir"]
                log("[%s] Storing Mail in %s" % (message_id, folder), STD_OUT)
                self.store_mail_in_folder(maildir, message, create_dir, folder)
            # If nothing matches
            else:
                log("[%s] Storing mail in std. folder" % (message_id), STD_OUT)
                self.store_mail_in_folder(maildir, message, message_id)
        except StandardError, err:
            log("Programm Error: %s" % (err), STD_ERR)
            log("[%s] Storing mail in std. folder" % (message_id), STD_OUT)
            self.store_mail_in_folder(maildir, message)
        except FolderCreationDenied:
            log("[%s] Creation of folder %s is denied" % (message_id, folder), STD_OUT)
            log("[%s] Storing mail in std. folder" % (message_id), STD_OUT)
            self.store_mail_in_folder(maildir, message)

    def store_mail_in_folder(self, maildir, message, create_dir=False, folder=None, message_id=None):
        if folder is not None:
                maildir_folder = self.get_folder(maildir, folder, create_dir, message_id)
                maildir_folder.add(message)
        else:
            maildir.add(message)


def run_test(username, maildir, config, message):
    domain = socket.gethostname()
    print "username:", username, "maildir:", maildir, "domain:", domain
    path = "%s %s%s %s%s %s%s" % (sys.executable, "--maildir=", maildir, "--username=", username, "--config=", config)
    log("Running: %s" % path, STD_OUT)
    fd = os.popen(path, "w")
    fd.write(message)
    fd.close()


def read_test_emails(username, maildir, config, test_data_dir):
    log("Using test-data from directory: %s" % test_data_dir, STD_OUT)
    for entry in os.listdir(test_data_dir):
        test_mail_path = os.path.join(test_data_dir, entry)
        if os.path.isfile(test_mail_path) and test_mail_path.endswith(".mail"):
            log("Reading Test E-Mail: %s" % test_mail_path, STD_OUT)
            fh = open(test_mail_path, 'r')
            message = fh.read()
            fh.close()
            run_test(username, maildir, config, message)


def test(username, maildir, config):
    domain = socket.gethostname()
    print "username:", username, "maildir:", maildir, "domain:", domain
    path = "%s %s%s %s%s" % (sys.executable, "--maildir=", maildir, "--username=", username, "--config=", config)
    print path


    message1 = """Subject: [SPAM] Postler Test
From: postler@%s
To: %s@%s
X-Spam: YES

Dies ist eine automatisch generierte Test E-Mail von Postler
""" % (socket.gethostname(), username, domain)

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


def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "h", ["help", "self-test", "test-data-dir=", "test-mail=", "clean-up", "config=", "username=", "maildir="])
    except getopt.GetoptError, err:
        # print help information and exit:
        sys.stderr.write(str(err)+"\n") # will print something like "option -a not recognized"
        #usage()
        sys.exit(2)

    self_test = False
    clean_up = False
    maildir = None
    test_data_dir = None
    test_mail = None
    config = "/etc/postler/config.tps"
    #username = os.getusername()
    username = os.getenv("USER")

    for o, a in opts:
        if o == "--username":
            username = a
            userinfo = pwd.getpwnam(username)

            uid = userinfo[2]
            gid = userinfo[3]

            log("User ID: %s" % uid, STD_OUT)
            log("Group ID: %s" % gid, STD_OUT)

            os.setuid(uid)
            #os.setgid(gid)
        elif o == "--maildir":
            maildir = a
        elif o == "--test-data-dir":
            test_data_dir = a
        elif o == "--test-mail":
            test_mail = a
        elif o == "--config":
            config = os.path.abspath(a)
        elif o == "--self-test":
            self_test = True
        elif o == "--clean-up":
            clean_up = True

    if maildir == None:
        maildir = "/home/%s/mails" % username
    else:
        maildir = maildir.replace("$USER", username)
    log("Maildir: %s" % maildir, STD_OUT)
    if self_test:
        if test_data_dir is not None:
            read_test_emails(username, maildir, config, test_data_dir)
        elif test_mail is not None:
            fh = open(test_mail, 'r')
            message = fh.read()
            fh.close()
            run_test(username, maildir, config, message)
        else:
            test(username, maildir, config)
    else:
        postler = Postler(config, maildir, username)
        if clean_up:
            postler.clean_up()
        else:
            postler.get_mail()


if __name__ == "__main__":
    main()