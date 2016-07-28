# -*- coding: utf-8 -*-

import os
import re
import socket
import email

from c_lua cimport lua_State, luaL_newstate, luaL_openlibs, luaL_loadfile, lua_pcall, lua_close, lua_pushcfunction, lua_setglobal, lua_getglobal, lua_tonumber, lua_pushnumber, luaL_checkstring, lua_toboolean, lua_tointeger, lua_pushlightuserdata, lua_rawlen, lua_pushinteger, lua_pop, lua_rawgeti, luaL_getn, lua_tolstring, lua_tostring, lua_isstring, lua_typename, lua_type, lua_next, lua_pushnil, lua_istable, lua_isinteger, lua_isnumber, lua_isboolean, lua_touserdata, lua_pushboolean, lua_pushcclosure, lua_getmetatable, lua_newuserdata, luaL_getmetatable, lua_setmetatable, lua_pushstring, lua_upvalueindex, luaL_newmetatable, lua_settable, lua_isfunction, lua_gettop, lua_setfield, lua_newtable, luaL_ref, LUA_REGISTRYINDEX, lua_isnil, lua_pushvalue, lua_Integer, lua_getinfo, lua_Debug, lua_getstack, LUA_TSTRING, LUA_TBOOLEAN, LUA_TNUMBER, LUA_MASKLINE, lua_sethook, lua_pushlstring


cdef:
    object lua_log_err
    object lua_log_out
    object lua_log_debug

    int current_line = 0

log_path = "log/lua/"
if not os.path.exists(log_path):
    os.makedirs(log_path)
lua_log_err = open('%slua.err' % log_path, 'a')
lua_log_out = open('%slua.out' % log_path, 'a')
lua_log_debug = open('%slua.debug' % log_path, 'a')


cdef lua_stack_dump(lua_State *L):
    cdef:
        int i
        int t
        int top = lua_gettop(L)

    for i in range(0, top): 
        t = lua_type(L, i);
        if t == LUA_TSTRING:
            print lua_tostring(L, i)
        elif t == LUA_TBOOLEAN:
            print lua_toboolean(L, i)
        elif t == LUA_TNUMBER:
            print lua_tonumber(L, i)
        else:
            print lua_typename(L, t)


cdef void lua_hook(lua_State* L, lua_Debug *ar):
    global current_line
    lua_getinfo(L, "n", ar)
    current_line = ar.currentline


cdef int lua_get_current_line_number(lua_State *L):
    cdef:
        lua_Debug ar
        int line
        int level = 0
    """
    This function fills parts of a lua_Debug structure with an identification of the activation record of the function executing at a given level. Level 0 is the current running function, whereas level n+1 is the function that has called level n (except for tail calls, which do not count on the stack). When there are no errors, lua_getstack returns 1; when called with a level greater than the stack depth, it returns 0. 
    """
    if lua_getstack(L, level, &ar) == 0:
        return -1
    """
    Each character in the string what selects some fields of the structure ar to be filled or a value to be pushed on the stack:
        'n': fills in the field name and namewhat;
        'S': fills in the fields source, short_src, linedefined, lastlinedefined, and what;
        'l': fills in the field currentline;
        'u': fills in the field nups;
        'f': pushes onto the stack the function that is running at the given level;
        'L': pushes onto the stack a table whose indices are the numbers of the lines that are valid on the function. (A valid line is a line with some associated code, that is, a line where you can put a break point. Non-valid lines include empty lines and comments.)

    This function returns 0 on error (for instance, an invalid option in what). 
    """
    lua_getinfo(L, <const char*>"nSl", &ar)
    line = ar.currentline
    return line


cdef unicode lua_string_to_python_unicode(lua_State *L, int index):
    cdef:
        const char *lua_string = ""
        size_t length = 0
    lua_string = lua_tolstring (L, index, &length)
    return lua_string[:length].decode("utf-8")


cdef int l_log_debug(lua_State *L):
    cdef const char* msg = luaL_checkstring(L, 1)
    return 0


cdef int l_log_info(lua_State *L):
    cdef const char* msg = luaL_checkstring(L, 1)
    return 0


cdef int l_log_warn(lua_State *L):
    cdef const char* msg = luaL_checkstring(L, 1)
    return 0


cdef int l_log_err(lua_State *L):
    cdef const char* msg = luaL_checkstring(L, 1)
    return 0


cdef lua_push_logging(lua_State *l):
    lua_pushcfunction(l, l_log_debug)
    lua_setglobal(l, "log_debug")

    lua_pushcfunction(l, l_log_info)
    lua_setglobal(l, "log_info")

    lua_pushcfunction(l, l_log_warn)
    lua_setglobal(l, "log_warn")

    lua_pushcfunction(l, l_log_err)
    lua_setglobal(l, "log_err")


cdef int l_startswith(lua_State *L):
    cdef:
        const char* var1 = luaL_checkstring(L, 1)
        const char* var2 = luaL_checkstring(L, 2)
    lua_pushboolean(L, var1.startswith(var2))
    return 1


cdef int l_endswith(lua_State *L):
    cdef:
        const char* var1 = luaL_checkstring(L, 1)
        const char* var2 = luaL_checkstring(L, 2)
    lua_pushboolean(L, var1.endswith(var2))
    return 1


cdef int l_regex(lua_State *L):
    cdef:
        bint ret_val
        const char* regex = luaL_checkstring(L, 1)
        const char* parameter2 = luaL_checkstring(L, 2)
    ret_val = (re.search(regex, parameter2) is not None)
    lua_pushboolean(L, ret_val)
    return 1


cdef class Parser:
    cdef:
        lua_State* _l
        basestring _config
        dict _variables
        object _email_message

    def __init__(self, config):
        self._config = config
        self._variables = {
            #"folder": None,
            "create dir": True
        }


    def _lua(self):
        cdef:
            int ret_code
            const char* err_msg
        global lua_log_err
        # Create Lua state variable
        self._l = luaL_newstate()
        # Load Lua libraries
        luaL_openlibs(self._l)
        #lua_pushcfunction(self._l, l_register_package)
        #lua_setglobal(self._l, "register_package")

        lua_push_logging(self._l)

        lua_pushcfunction(self._l, l_startswith)
        lua_setglobal(self._l, "startswith")

        lua_pushcfunction(self._l, l_endswith)
        lua_setglobal(self._l, "endswith")

        lua_pushcfunction(self._l, l_regex)
        lua_setglobal(self._l, "regex")

        self._create_lua_table(self._email_message, "header")

        #lua_push_logging(self._l)
        # Load but don't run the Lua script 
        if luaL_loadfile(self._l, self._config):
            #print "luaL_loadfile(%s) failed!" % self._settings_path
            err_msg = lua_tostring(self._l, -1)
            #print >>sys.stderr, err_msg
            print >>lua_log_err, err_msg
            return False

        # Run the lua
        ret_code = lua_pcall(self._l, 0, 0, 0)
        if ret_code == 2:
            err_msg = lua_tostring(self._l, -1)
            #print >>sys.stderr, err_msg
            print >>lua_log_err, err_msg
        if ret_code != 0:
            #print "lua_pcall() failed!"
            return False

        self._variables["folder"] = self._lua_get_string("folder", None)
        self._variables["create_dir"] = self._lua_get_boolean("create_dir")

    #cdef unicode _lua_get_string(self, const char *var_name, object default_value=u""):
    cdef object _lua_get_string(self, const char *var_name, object default_value=u""):
        lua_getglobal(self._l, var_name)
        if lua_isstring(self._l, -1):
            return lua_string_to_python_unicode(self._l, -1)
        print >>lua_log_err, u"%s is not a string" % var_name
        return default_value

    cdef int _lua_get_int(self, const char *var_name):
        lua_getglobal(self._l, var_name)
        if lua_isinteger(self._l, -1):
            return lua_tointeger(self._l, -1)
        print >>lua_log_err, u"%s is not an integer" % var_name
        return 0

    cdef int _lua_get_boolean(self, const char *var_name):
        lua_getglobal(self._l, var_name)
        if lua_isboolean(self._l, -1):
            return lua_toboolean(self._l, -1)
        print >>lua_log_err, u"%s is not a boolean" % var_name
        return False

    def parse(self, email_message):
        self._email_message = email_message
        self._variables = {
            #"folder": None,
            "create dir": True
        }
        self._lua()
        return self

    def _create_lua_table(self, iterator, table_name):
        cdef:
            int top
            basestring key
            basestring value

        lua_newtable(self._l);
        top = lua_gettop(self._l);

        for key, value in iterator.items():
            lua_pushlstring(self._l, <const char*>key, len(key))
            lua_pushlstring(self._l, <const char*>value, len(value))
            lua_settable(self._l, top)

        lua_setglobal(self._l, table_name);

    def __iter__(self):
        return iter(self._variables)

    def __getitem__(self, key):
        return self._variables[key]

    def __setitem__(self, key, value):
        self._variables[key] = value


def get_parser(config):
    parser = Parser(config)
    return parser


if __name__ == "__main__":
    # Test Config
    config = """
            """

    #FIXME
    parser = Parser()

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
