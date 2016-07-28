cdef extern from "stdarg.h":
    ctypedef struct va_list:
        pass

cdef extern from "lua.h":
    int LUA_TNIL                = 0
    int LUA_TBOOLEAN            = 1
    int LUA_TLIGHTUSERDATA      = 2
    int LUA_TNUMBER             = 3
    int LUA_TSTRING             = 4
    int LUA_TTABLE              = 5
    int LUA_TFUNCTION           = 6
    int LUA_TUSERDATA           = 7
    int LUA_TTHREAD             = 8

    #
    # Event codes
    #
    int LUA_HOOKCALL	= 0
    int LUA_HOOKRET	= 1
    int LUA_HOOKLINE	= 2
    int LUA_HOOKCOUNT	= 3
    int LUA_HOOKTAILRET = 4

    #
    # Event masks
    #
    int LUA_MASKCALL	= (1 << LUA_HOOKCALL)
    int LUA_MASKRET	    = (1 << LUA_HOOKRET)
    int LUA_MASKLINE	= (1 << LUA_HOOKLINE)
    int LUA_MASKCOUNT	= (1 << LUA_HOOKCOUNT)

    # Functions to be called by the debuger in specific events
    ctypedef void (*lua_Hook) (lua_State *L, lua_Debug *ar)

    int lua_sethook (lua_State *L, lua_Hook func, int mask, int count)
    lua_Hook lua_gethook (lua_State *L)
    int lua_gethookmask (lua_State *L)
    int lua_gethookcount (lua_State *L)

cdef extern from "luaconf.h":
    pass

cdef extern from "lvm.h":
    pass

cdef extern from "lauxlib.h":
    pass

cdef extern from "lualib.h":
    ctypedef size_t lu_mem
    ctypedef ptrdiff_t l_mem
    ctypedef unsigned char lu_byte

    #ctypedef LUA_NUMBER lua_Number
    #ctypedef LUA_INTEGER lua_Integer
    #ctypedef LUA_UNSIGNED lua_Unsigned
    #ctypedef LUA_KCONTEXT lua_KContext

    ctypedef float lua_Number
    ctypedef int lua_Integer
    ctypedef unsigned int lua_Unsigned
    ctypedef ptrdiff_t lua_KContext
    #ctypedef intptr_t lua_KContext

    #DEF TValuefields = Value value_; int tt_
    DEF LUA_IDSIZE = 60
    DEF luai_jmpbuf = int
    ctypedef void * (*lua_Alloc) (void *ud, void *ptr, size_t osize, size_t nsize)
    ctypedef void (*lua_Hook) (lua_State *L, lua_Debug *ar)
    ctypedef int (*lua_CFunction) (lua_State *L)

    ctypedef int luai_jmpbuf

    struct stringtable:
        TString **hash
        int nuse
        int size

    union Value:
        GCObject *gc
        void *p
        int b
        lua_CFunction f
        lua_Integer i
        lua_Number n

    struct lua_TValue:
        Value value_
        int tt_

    ctypedef lua_TValue TValue

    struct TKey_nk:
        Value value_
        int tt_
        int next

    union TKey:
        TKey_nk nk
        TValue tvk

    enum TMS:
        TM_INDEX,
        TM_NEWINDEX,
        TM_GC,
        TM_MODE,
        TM_LEN,
        TM_EQ,
        TM_ADD,
        TM_SUB,
        TM_MUL,
        TM_MOD,
        TM_POW,
        TM_DIV,
        TM_IDIV,
        TM_BAND,
        TM_BOR,
        TM_BXOR,
        TM_SHL,
        TM_SHR,
        TM_UNM,
        TM_BNOT,
        TM_LT,
        TM_LE,
        TM_CONCAT,
        TM_CALL,
        TM_N

    DEF TM_N = 24

    struct Node:
        TValue i_val
        TKey i_key

    struct Mbuffer:
        char *buffer
        size_t n
        size_t buffsize

    struct lua_TObject:
        int tt;
        Value value

    ctypedef lua_TObject TObject

    struct global_State:
        stringtable strt
        GCObject *rootgc
        GCObject *rootudata
        GCObject *tmudata
        Mbuffer buff
        lu_mem GCthreshold
        lu_mem nblocks
        lua_CFunction panic
        TObject _registry
        TObject _defaultmeta
        lua_State *mainthread
        Node dummynode[1]
        TString *tmname[TM_N]

    struct lua_longjmp:
        lua_longjmp *previous
        luai_jmpbuf b
        int status

    ctypedef unsigned int Instruction
    ctypedef TValue *StkId
    ctypedef int (*lua_CFunction) (lua_State *L)
    ctypedef int (*lua_KFunction) (lua_State *L, int status, lua_KContext ctx)

    #DEF CommonHeader = GCObject *next; lu_byte tt; lu_byte marked

    struct lua_Debug:
        int event
        const char *name
        const char *namewhat
        const char *what
        const char *source
        int currentline
        int linedefined
        int lastlinedefined
        unsigned char nups
        unsigned char nparams
        char isvararg
        char istailcall
        char short_src[LUA_IDSIZE]
        CallInfo *i_ci

    struct GCObject:
        GCObject *next
        lu_byte tt
        lu_byte marked

    union Value:
        GCObject *gc
        void *p
        int b
        lua_CFunction f
        lua_Integer i
        lua_Number n

    struct lua_TValue:
        Value value_
        int tt_

    struct TString:
        GCObject *next
        lu_byte tt
        lu_byte marked

        lu_byte extra
        unsigned int hash
        size_t len
        TString *hnex

    struct stringtable:
        TString **hash
        int nuse
        int size

    struct UpVal_open:
        UpVal *next
        int touched

    union UpVal_u:
        UpVal_open open
        TValue value

    struct UpVal:
        TValue *v
        lu_mem refcount
        UpVal_u u

    struct CallInfo_u_l:
        StkId base
        const Instruction *savedpc

    struct CallInfo_u_c:
        lua_KFunction k
        ptrdiff_t old_errfunc
        lua_KContext ctx

    union CallInfo_u:
        CallInfo_u_l l
        CallInfo_u_c c

    struct CallInfo:
        StkId func
        StkId top
        CallInfo *previous
        CallInfo *next
        CallInfo_u u
        ptrdiff_t extra
        short nresults
        lu_byte callstatus

    struct lua_State:
        GCObject *next
        lu_byte tt
        lu_byte marked
        lu_byte status
        StkId top
        global_State *l_G
        CallInfo *ci
        const Instruction *oldpc
        StkId stack_last
        StkId stack
        UpVal *openupval
        GCObject *gclist
        lua_State *twups
        lua_longjmp *errorJmp
        CallInfo base_ci
        lua_Hook hook
        ptrdiff_t errfunc
        int stacksize
        int basehookcount
        int hookcount
        unsigned short nny
        unsigned short nCcalls
        lu_byte hookmask
        lu_byte allowhook

    lua_State *luaL_newstate ()
    void luaL_openlibs (lua_State *L)
    int luaL_loadfile (lua_State *L, const char *filename)
    int lua_pcall (lua_State *L, int nargs, int nresults, int msgh)
    void lua_close (lua_State *L)

    # push functions (C -> stack)
    void        lua_pushnil (lua_State *L)
    void        lua_pushnumber (lua_State *L, lua_Number n)
    void        lua_pushinteger (lua_State *L, lua_Integer n)
    const char *lua_pushlstring (lua_State *L, const char *s, size_t len)
    const char *lua_pushstring (lua_State *L, const char *s)
    const char *lua_pushvfstring (lua_State *L, const char *fmt, va_list argp)
    const char *lua_pushfstring (lua_State *L, const char *fmt, ...)
    void  lua_pushcclosure (lua_State *L, lua_CFunction fn, int n)
    void  lua_pushboolean (lua_State *L, int b)
    void  lua_pushlightuserdata (lua_State *L, void *p)
    int   lua_pushthread (lua_State *L)


    # get functions (Lua -> stack)
    int lua_getglobal (lua_State *L, const char *name)
    int lua_gettable (lua_State *L, int idx)
    int lua_getfield (lua_State *L, int idx, const char *k)
    int lua_geti (lua_State *L, int idx, lua_Integer n)
    int lua_rawget (lua_State *L, int idx)
    int lua_rawgeti (lua_State *L, int idx, lua_Integer n)
    int lua_rawgetp (lua_State *L, int idx, const void *p)

    void  lua_createtable (lua_State *L, int narr, int nrec)
    void *lua_newuserdata (lua_State *L, size_t sz)
    int   lua_getmetatable (lua_State *L, int objindex)
    int  lua_getuservalue (lua_State *L, int idx)

    # access functions (stack -> C)

    int             lua_isnumber (lua_State *L, int idx)
    int             lua_isstring (lua_State *L, int idx)
    int             lua_iscfunction (lua_State *L, int idx)
    int             lua_isinteger (lua_State *L, int idx)
    int             lua_isboolean (lua_State *L, int index)
    int             lua_isuserdata (lua_State *L, int idx)
    int             lua_type (lua_State *L, int idx)
    const char     *lua_typename (lua_State *L, int tp)
    int             lua_isfunction (lua_State *L, int index)

    #lua_Number      lua_tonumber (lua_State *L, int idx, int *isnum)
    #lua_Integer     lua_tointeger (lua_State *L, int idx, int *isnum)
    lua_Number      lua_tonumber (lua_State *L, int idx)
    lua_Integer     lua_tointeger (lua_State *L, int idx)
    int             lua_toboolean (lua_State *L, int idx)
    const char     *lua_tolstring (lua_State *L, int idx, size_t *len)
    size_t          lua_rawlen (lua_State *L, int idx)
    lua_CFunction   lua_tocfunction (lua_State *L, int idx)
    void	       *lua_touserdata (lua_State *L, int idx)
    lua_State      *lua_tothread (lua_State *L, int idx)
    const void     *lua_topointer (lua_State *L, int idx)
    const char *lua_tostring (lua_State *L, int index)

    void lua_setglobal (lua_State *L, const char *name)
    void lua_pushcfunction (lua_State *L, lua_CFunction fn)

    const char *luaL_checkstring (lua_State *L, int arg)
    void lua_pop (lua_State *L, int n)
    int luaL_getn (lua_State *L, int t)
    int lua_next (lua_State *L, int index)
    int lua_istable (lua_State *L, int index)

    void luaL_getmetatable (lua_State *L, const char *tname)
    int lua_setmetatable (lua_State *L, int index)
    int luaL_newmetatable (lua_State *L, const char *tname)
    int lua_upvalueindex (int i)
    void lua_settable (lua_State *L, int index)
    int lua_gettop (lua_State *L)
    void lua_setfield (lua_State *L, int index, const char *k)
    void lua_newtable (lua_State *L)
    int luaL_ref (lua_State *L, int t)
    int lua_isnil (lua_State *L, int index)
    void lua_pushvalue (lua_State *L, int index)    
    int LUA_REGISTRYINDEX
    int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar)
    int lua_getstack (lua_State *L, int level, lua_Debug *ar)