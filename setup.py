import os
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
from Cython.Build import cythonize

packages = ("config")
cmdclass = {'build_ext': build_ext}
compile_args = ["-m%s" % os.environ['TARGET_ARCH']]
#extra_link_args = [r'/MACHINE:%s' % os.environ['MACHINE']]
#library_dir = [os.environ['PYTHON_LIBS_PATH']]
library_dir = ['/usr/lib']
#include_dirs = [os.environ['PYTHON_INCLUDE_PATH']]
include_dirs = ['/usr/include/python2.7']

ext_modules = [
    Extension('config.tps',
        sources=['config/tps.pyx'],
        extra_compile_args=compile_args,
        #include_dirs = include_dirs,
        #libraries = [],
        #library_dirs = library_dir
    ),
    Extension('config.lua',
        sources=['config/lua.pyx'],
        #extra_compile_args=compile_args,
        include_dirs = include_dirs + ['lua/lua-5.3.1/src'],
        libraries = ['lua'],
        library_dirs = library_dir + ['lua/lua-5.3.1/src']
    ),
    Extension('log',
        sources=['log.pyx'],
        extra_compile_args=compile_args,
        #include_dirs = include_dirs,
        #libraries = [],
        #library_dirs = library_dir
    )
]

setup(
    name='postler',
    version='1.2.0.0',
    author='Richard Lamboj',
    author_email='rl@unicom.ws',
    ext_modules=cythonize(ext_modules, gdb_debug=False),
    cmdclass=cmdclass,
    packages=packages
)
#  Build --------------------------
#  python setup.py build_ext --inplace