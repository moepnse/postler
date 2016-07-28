# -*- coding: utf-8 -*-

import re
import socket
import email

KEYWORD = 0
OPERATOR = 1
QUOTE = 2
VARIABLE = 3

KEYWORD_CHARS = ["a",  "b",  "c",  "d", "e",  "f", "g", "h",  "i",  "j", "k", "l", "m", "n",  "o", "p",  "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "_", "-"]

QUOTE_END_CHAR = "\""
QUOTE_START_CHAR = "\""
QUOTE_ESCAPE_CHAR = "\\"

OPERATORS = ["==", "!=", "and", "=", "!"]

STATEMENT_END_CHAR = ")"
STATEMENT_START_CHAR = "("

CONDITION_GROUP_END_CHAR = ")"
CONDITION_START_CHAR = "("

KEYWORD = 0
OPERATOR = 1
STATEMENT_START = 2
STATEMENT_END = 3
CONDITION_GROUP_START = 2
CONDITION_GROUP_END = 3
LINE_END = 4

"""
IF = "if"
  ^
------------------------------------------------------------

config/tps.pyx:35:3: Expected an identifier or literal
"""
_IF = "if"
END = "end"
THEN = "then"
ASSIGMENT = "="
EQ_OPERATOR = "=="
NOT_EQ_OPERATOR = "!="
REGEX = "regex"
CREATE_DIR = "create dir"
FOLDER = "folder"
SET = "set"
AND = "and"
OR = "or"
NOT = "not"
TRUE = "True"
FALSE = "False"
NEWLINE = "\n"

KEYWORDS = [_IF,
    END,
    THEN,
    ASSIGMENT,
    EQ_OPERATOR,
    NOT_EQ_OPERATOR,
    REGEX,
    CREATE_DIR,
    FOLDER,
    SET,
    AND,
    OR,
    NOT,
    TRUE,
    FALSE,
    True,
    False
]

ALLOWED_VARIABLES = [FOLDER, CREATE_DIR]

class Tree:
    def __init__(self):
        self._sub = []
    def append(self, sub):
        self._sub.append(sub)

# Iterator
class TokensList(object):

    _iterators = []

    def __init__(self, tokens_list=[]):
        self._tokens_list = tokens_list
        self._length = len(tokens_list) - 1
        self.index = -1
        TokensList._iterators.append(self)

    def __iter__(self):
        self.index = -1
        return self

    def next(self):
        if self.index >= self._length:
            self.index = -1
            raise StopIteration
        self.index += 1
        return self._tokens_list[self.index]

    def __str__(self):
        return str(self._tokens_list)

    def __repr__(self):
        return repr(self._tokens_list)

    @staticmethod
    def reset_all_iterators():
        for iterator in TokensList._iterators:
            iterator.index = -1


# Iterator
class Scanner(object):
    def __init__(self, source_code=""):
        self._source_code = source_code
        self._source_length = len(source_code) - 1
        self.pos = 0

    def __iter__(self):
        return self

    def next(self):
        if self.pos > self._source_length:
            raise StopIteration
        self.pos += 1
        return self._source_code[self.pos-1:self.pos]

    def set_source_code(self, source_code):
        self._source_code = source_code
        self._source_length = len(source_code) - 1


class Tokens(object):
    def __init__(self, typ, tokens):
        self.tokens = tokens
        self.typ = typ

    def __repr__(self):
        return repr(self.tokens)

    def __str_(self):
        return str(self.tokens)


class Lexer(object):

    def __init__(self, source_code):

        self._scanner = Scanner()
        self._scanner.set_source_code(source_code)
        self._tokens = []
        puffer = ""

    def scan(self):

        tokens = []

        puffer = ""
        for token in self._scanner:
            # Quotes
            if token == QUOTE_START_CHAR:

                last_token = ""
                #puffer = token
                #reset puffer
                puffer = ""
                for token in self._scanner:
                    if token == QUOTE_END_CHAR and last_token != QUOTE_ESCAPE_CHAR:
                        tokens.append(Tokens(QUOTE, puffer))
                        break
                    puffer += token
                    last_token = token
                continue

            # Keywords
            if token.lower() in KEYWORD_CHARS:
                puffer = token
                for token in self._scanner:
                    if token.lower() in KEYWORD_CHARS:
                        puffer += token
                        continue
                    if puffer == "True":
                        puffer = True
                    elif puffer == "False":
                        puffer = False
                    if puffer in KEYWORDS:
                        tokens.append(Tokens(KEYWORD, puffer))
                    else:
                        tokens.append(Tokens(VARIABLE, puffer))
                    # Statement
                    if token == STATEMENT_END_CHAR:
                        #tokens.append(Tokens(STATEMENT_END, token))
                        return TokensList(tokens)
                    elif token == STATEMENT_START_CHAR:
                        #tokens.append(Tokens(STATEMENT_START, token))
                        tokens.append(self.scan())
                    if puffer == _IF:
                        pass
                    elif puffer == THEN:
                        tokens.append(self.scan())
                    elif puffer == END:
                        #tokens.append(Tokens(KEYWORD, puffer))
                        puffer = ""
                        for token in self._scanner:
                            if token == " ":
                                puffer = ""
                                continue
                            if puffer == _IF:
                                #tokens.append(Tokens(KEYWORD, puffer))
                                return TokensList(tokens)
                            puffer += token
                    # reset puffer
                    puffer = ""
                    break
                # decrease scanner position, becouse we made a lookahead
                #self._scanner.pos -= 1
                continue

            # Operators
            # FIXME
            if token in OPERATORS:
                puffer = token
                for token in self._scanner:
                    if token.lower() in OPERATORS:
                        puffer += token
                        continue
                    tokens.append(Tokens(OPERATOR, puffer))
                    # reset puffer
                    puffer = ""
                    break
                # decrease scanner position, becouse we made a lookahead
                self._scanner.pos -= 1
                continue

            # Statement
            if token == STATEMENT_END_CHAR:
                #tokens.append(Tokens(STATEMENT_END, token))
                return TokensList(tokens)
            elif token == STATEMENT_START_CHAR:
                #tokens.append(Tokens(STATEMENT_START, token))
                tokens.append(self.scan())

            if token == NEWLINE:
                tokens.append(Tokens(LINE_END, token))
        return TokensList(tokens)


class Parser(object):
    def __init__(self, tokens_list=[]):
        self._tokens_list = tokens_list
        self._variables = {
            #"folder": None,
            "create dir": True
        }

    def _handle_if(self, tokens_list):
        #tokens_list.index = -1
        ret_val = False
        try:
            while 1:
                tokens = tokens_list.next()
                if isinstance(tokens, TokensList):
                    ret_val = self._handle_if(tokens)
                elif tokens.tokens in (AND, OR):
                    last_tokens = tokens
                    tokens = tokens_list.next()
                    if isinstance(tokens, TokensList):
                        ret_val2 = self._handle_if(tokens)
                    else:
                        tokens_list.index -= 1
                        ret_val2 = self._handle_condition(tokens_list)
                    if last_tokens.tokens == AND:
                        ret_val = (ret_val and ret_val2)
                    elif last_tokens.tokens == OR:
                        ret_val = (ret_val or ret_val2)
                    if not ret_val:
                        return False
                else:
                    tokens_list.index -= 1
                    ret_val = self._handle_condition(tokens_list)
        except StopIteration:
            return ret_val

    def _handle_regex(self, tokens_list):
        #tokens_list.index = -1
        tokens = tokens_list.next()
        regex = tokens.tokens
        tokens = tokens_list.next()
        parameter2 = tokens.tokens
        parameter2 = self._email_message.__getitem__(parameter2)
        if parameter2 is None:
            return False
        ret_val = (re.search(regex, parameter2) is not None)
        return ret_val

    def _get(self, tokens_list, tokens):
        if tokens.typ == KEYWORD:
            if tokens.tokens == REGEX:
                tokens = tokens_list.next()
                if isinstance(tokens, TokensList):
                    return self._handle_regex(tokens)
                else:
                    print "Error: Expected %s" % (STATEMENT_START_CHAR)
            else:
                return tokens.tokens
        elif tokens.typ == VARIABLE:
            return self._email_message.__getitem__(tokens.tokens)
        elif tokens.typ == QUOTE:
            return tokens.tokens
        else:
            print "Unknown typ: %s (%s)" % (tokens.typ, tokens.tokens)
        return None

    def _handle_condition(self, tokens_list):
        ret_val = False
        #tokens_list.index = -1
        tokens = tokens_list.next()
        left = self._get(tokens_list, tokens)
        tokens = tokens_list.next()
        operator = tokens.tokens
        tokens = tokens_list.next()
        right = self._get(tokens_list, tokens)
        if operator == EQ_OPERATOR:
            ret_val = (left == right)
        elif operator == NOT_EQ_OPERATOR:
            ret_val = (left != right)
        return ret_val

    def parse(self, email_message):
        #self._tokens_list.index = -1
        TokensList.reset_all_iterators()
        self._email_message = email_message
        self._variables = {
            #"folder": None,
            "create dir": True
        }
        self._parse(self._tokens_list)
        return self

    def _parse(self, tokens_list):
        ret_val = False
        for tokens in tokens_list:
            value_is_regex = False
            field = ""
            value = ""
            folder = ""
            create_dir = False
            if isinstance(tokens, TokensList):
                self._parse(tokens)
            elif tokens.tokens == _IF:
                tokens = tokens_list.next()
                ret_val = self._handle_if(tokens)
            elif tokens.tokens == THEN:
                tokens = tokens_list.next()
                if ret_val:
                    self._parse(tokens)
            elif tokens.tokens == SET:
                tokens = tokens_list.next()
                variable_name = tokens.tokens
                while 1:
                    tokens = tokens_list.next()
                    if tokens.tokens == ASSIGMENT:
                        if variable_name in ALLOWED_VARIABLES:
                            tokens = tokens_list.next()
                            self[variable_name] = tokens.tokens
                        else:
                            print "Variable %s not allowed!" % variable_name
                        break
                    variable_name += " " + tokens.tokens

    def __iter__(self):
        return iter(self._variables)

    def __getitem__(self, key):
        return self._variables[key]

    def __setitem__(self, key, value):
        self._variables[key] = value


def get_parser(config):
    fh = open(config, "r")
    config_src = fh.read()
    fh.close()
    lexer = Lexer(config_src)
    tokens_list = lexer.scan()
    #print tokens_list
    parser = Parser(tokens_list)
    return parser


if __name__ == "__main__":
    # Test Config
    config = """
    if (X-Spam == "YES") then
        set create dir = True
        set folder = "Spam"
    end if

    if (X-Virus == "YES") then
        set create dir = True
        set folder = "Virus"
    end if

    if (regex("[\w]*@ams.at", From) == True) then
        set create dir = True
        set folder = "AMS"
    end if

    if (regex("[\w]*@unicom.ws", From) == True and (X-Spam != "Yes" and X-Virus != "Yes")) then
        set folder = "Mitarbeiter"
    end if
    """
    #config = """if (X-SPAM == YES) then
    #    set folder = spam
    #    set create dir = True
    #end if"""
    #config = """if (regex("[\w]*@unicom.ws", From) == True and X-Spam != Yes) then
    #    set create dir = True
    #    set folder = Mitarbeiter
    #end if"""
    #config = """if (From == "unicom.ws") and ((X-Spam == Yes) or (X-Virus == Yes)) then
    #    set folder = Mitarbeiter
    #end if"""
    #config = """if (X-Virus == YES) then
    #    set create dir = True
    #    set folder = Virus
    #end if"""
    lexer = Lexer(config)

    tokens_list = lexer.scan()
    print tokens_list
    parser = Parser(tokens_list)

    # Test User
    username = "user1"
    domain = "%s"

    # Spam E-Mail
    message1 = """Subject: [SPAM] Postler
From: postler@%s
To: %s@%s
X-Spam: YES

Dies ist eine Automatisch generierte Test E-Mail von Postler
""" % (socket.gethostname(), username, domain)

    msg1 = email.message_from_string(message1)

    # Virus E-Mail
    message2 = """Subject: [VIRUS] Postler
From: postler@%s
To: %s@%s
X-Virus: YES

Dies ist eine Automatisch generierte Test E-Mail von Postler
""" % (socket.gethostname(), username, domain)

    msg2 = email.message_from_string(message2)

    # Normal E-Mail
    message3 = """Subject: [NORMAL] Postler
From: postler@%s
To: %s@%s

Dies ist eine Automatisch generierte Test E-Mail von Postler
""" % (socket.gethostname(), username, domain)

    msg3 = email.message_from_string(message3)

    # AMS(Arbeits Markt Service) E-Mail
    message4 = """Subject: [AMS] Postler
From: mitarbeiter1@ams.at
To: %s@%s

Dies ist eine Automatisch generierte Test E-Mail von Postler
""" % (username, domain)

    msg4 = email.message_from_string(message4)

    # unicom E-Mail
    message5 = """Subject: [unicom] Postler
From: rl@unicom.ws
To: %s@%s

Dies ist eine Automatisch generierte Test E-Mail von Postler
""" % (username, domain)

    msg5 = email.message_from_string(message5)

    print "Spam,", parser.parse(msg1)["folder"]
    print "Virus,", parser.parse(msg2)["folder"]
    print "None,", parser.parse(msg3)["folder"]
    print "AMS,", parser.parse(msg4)["folder"]
    print "Mitarbeiter,", parser.parse(msg5)["folder"]
