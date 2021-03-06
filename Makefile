######################################
# Top level switch
######################################

ifdef OPT
# do nothing
else
#OPT = opt
#OPT = dev
OPT = optdev
#OPT = release
endif

######################################
# Commands/Compilers
######################################
AR      = ar
#GCC_VER = 4.8.1
#GCC_ROOT = /usr/intel/pkgs/gcc/$(GCC_VER)
#CXX     = $(GCC_ROOT)/bin/g++	
CXX	= g++
CD      = cd
CPRF    = cp -rf
DOXYGEN = doxygen
LDD     = ldd
LN      = ln
RMF     = rm -f
RMRF    = rm -rf

######################################
# Paths to tools and libs
######################################
PWD = $(shell pwd)
SYS = $(shell /usr/intel/bin/sysname -afs)
BASEDIR = $(PWD)
SVI_ROOT = $(shell realpath ${BASEDIR}/../svinterface)

ifdef BUILD_DIR
else
BUILD_DIR = $(BASEDIR)
endif

######################################
# Library names and info
######################################
APPNAME = amsr
MAIN = suMain
OBJ = obj_$(OPT)
BIN_DIR = $(BUILD_DIR)/bin
LIB_DIR = $(BUILD_DIR)/lib
OBJ_DIR = $(BASEDIR)/$(OBJ)
LIBNAME = lib$(APPNAME)
SHARED_LIB = $(LIB_DIR)/$(LIBNAME).so
STATIC_LIB = $(LIB_DIR)/$(LIBNAME).a
EXECUTABLE_LIB = $(BIN_DIR)/$(APPNAME)_shared.exe
EXECUTABLE_SOLID = $(BIN_DIR)/$(APPNAME).exe
MAIN_SRC = $(SRC)/$(MAIN).cpp

######################################
# Finding Files to build
######################################
SRC = src
ALL_SOURCES =  $(wildcard $(SRC)/*.cpp)
DO_NOT_BUILD = $(wildcard $(MAIN_SRC))
LIB_SOURCES = $(filter-out $(DO_NOT_BUILD), $(ALL_SOURCES))
LIB_OBJECTS  = $(LIB_SOURCES:$(SRC)/%.cpp=$(OBJ)/%.o) 
LIB_DEPENDS = $(LIB_SOURCES:$(SRC)/%.cpp=$(OBJ)/%.d)
MAIN_OBJECT = $(OBJ)/$(MAIN).o
GLUCOSE_OBJECTS = $(OBJ)/glucose/Solver.o

######################################
# some extra info 
######################################
BUILD_USER = ${USER}
BUILD_DATE = $(shell date)
BUILD_HOST = ${HOSTNAME}
#SVNDIR = $(shell realpath .svn)
#ifneq ($(SVNDIR),)
#BUILD_REVISION = $(shell svn info | grep Revision | sed -e s/Revision://g)
#endif
BUILD_REVISION = $(shell git write-tree)
#BUILD_COMPILER = $(shell realpath ${CXX})
BUILD_COMPILER = $(shell which ${CXX})
BUILD_MODE = ${OPT}
BUILD_SECONDS = $(shell date +"%s")

######################################
# INCLUDES 
######################################
INCLUDES = -I./include
INCLUDES += -I$(GLUCOSE)

######################################
# Generic flags 
######################################
#ifeq ($(GCC_VER),4.8.1)
#GCC_XOPT_FLAGS = -std=c++11 -Wno-reorder -Wno-unused-function -Wunused-but-set-variable -Wunused-local-typedefs -Wparentheses -Wsign-compare -Wnarrowing -D_LG_GCC_VER_=40801
#endif
GCC_XOPT_FLAGS = -std=c++11 -Wno-reorder -Wno-unused-function -Wunused-but-set-variable -Wunused-local-typedefs -Wparentheses -Wsign-compare -Wnarrowing -D_LG_GCC_VER_=70400

ENABLE_SVI    = 0
RELEASE_BUILD = 0
DEFINES       =    
DEPRECATED    = -Wno-deprecated
WARNINGS      = -Wall

ifeq ($(OPT),dev)
OPTFLAG = -O0 -g -rdynamic -ffloat-store $(GCC_XOPT_FLAGS)
STRIP = ls -la
endif

ifeq ($(OPT),optdev)
OPTFLAG = -O3 -g -rdynamic -ffloat-store $(GCC_XOPT_FLAGS)
STRIP = ls -la
endif

ifeq ($(OPT),opt)
OPTFLAG = -O3 -ffloat-store $(GCC_XOPT_FLAGS)
STRIP = strip
endif

ifeq ($(OPT),release)
OPTFLAG = -O3 -rdynamic -ffloat-store $(GCC_XOPT_FLAGS)
RELEASE_BUILD = 1
ENABLE_SVI    = 0
STRIP = strip
endif

######################################
# CXXFLAGS
######################################
CXXFLAGS = $(OPTFLAG) $(DEPRECATED) $(WARNINGS) $(DEFINES) $(INCLUDES)
CXXFLAGS += -fPIC
# MiniSAT/Glucose; Without it, the problems are always unsatisfiable; since 4.2.2a
#CXXFLAGS += -fno-tree-pre

######################################
# External libraries
######################################

# external tools
SVI_LIBS = -L${SVI_ROOT}/lib -Wl,-rpath,${SVI_ROOT}/lib -lsvi

# Different versions have a bit different API; I don't want to use different solvers and want to use the same wrapper
#GLUCOSE_VERSION = _GLUCOSE_2_2_0_
#GLUCOSE_VERSION = _GLUCOSE_3_0_0_
GLUCOSE_VERSION = _GLUCOSE_4_1_0_

ifeq ($(GLUCOSE_VERSION),_GLUCOSE_2_2_0_)
GLUCOSE = ${BASEDIR}/vendor/Glucose_2.2.0/glucose2.2
endif

# 32-bit / 64-bit
ifeq ($(GLUCOSE_VERSION),_GLUCOSE_3_0_0_)
#GLUCOSE = ${BASEDIR}/vendor/Glucose_3.0.0/glucose-3.0
GLUCOSE = ${BASEDIR}/vendor/Glucose_3.64x/glucose-3.0
endif

#
ifeq ($(GLUCOSE_VERSION),_GLUCOSE_4_1_0_)
GLUCOSE = ${BASEDIR}/vendor/Glucose_4.1.0/glucose-syrup-4.1
#GLUCOSE = ${BASEDIR}/vendor/Glucose_4.1.pro/glucose-syrup-4.1
#DEFINES += -D_GLUCOSE_PRO_
endif

ifeq ($(RELEASE_BUILD),1)
DEFINES += -D_RELEASE_BUILD_
endif

ifeq ($(ENABLE_SVI),1)
DEFINES += -D_ENABLE_SVI_
INCLUDES += -I${SVI_ROOT}/include
endif

DEFINES += -D$(GLUCOSE_VERSION)

#DEFINES += -D_DEBUG_LAYOUT_FUNCTIONS_

DEFINES += -D_BUILD_USER_="\"${BUILD_USER}\""
DEFINES += -D_BUILD_DATE_="\"${BUILD_DATE}\""
DEFINES += -D_BUILD_HOST_="\"${BUILD_HOST}\""
DEFINES += -D_BUILD_MODE_="\"${BUILD_MODE}\""
DEFINES += -D_BUILD_REVISION_="\"${BUILD_REVISION}\""
DEFINES += -D_BUILD_COMPILER_="\"${BUILD_COMPILER}\""
DEFINES += -D_BUILD_SECONDS_=${BUILD_SECONDS}

# All external libs to build our shared lib
EXT_LIBS =

# need it for clock_gettime
EXT_LIBS += -lrt

ifeq ($(ENABLE_SVI),1)
EXT_LIBS += $(SVI_LIBS)
endif

# Project shared library build-in
PROJECT_SHARED_BUILDIN = -L$(LIB_DIR) -Wl,-rpath,$(LIB_DIR) -l$(APPNAME)

all: exec_no_lib
#all: exec_shared

init:
	@mkdir -p $(LIB_DIR)
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(OBJ_DIR)

# build shared library
shared: init $(LIB_OBJECTS) $(GLUCOSE_OBJECTS) 
	$(CXX) -o $(SHARED_LIB) -shared $(LIB_OBJECTS) $(EXT_LIBS) $(GLUCOSE_OBJECTS) 
	$(LDD) $(SHARED_LIB)
	$(STRIP) $(SHARED_LIB)

# build executable with a shared lib
exec_shared: shared $(MAIN_OBJECT)
	$(CXX) -o $(EXECUTABLE_LIB) $(MAIN_OBJECT) $(PROJECT_SHARED_BUILDIN)
	$(LDD) $(EXECUTABLE_LIB)
	$(STRIP) $(EXECUTABLE_LIB)

# build executable without a shared lib
exec_no_lib: init $(LIB_OBJECTS) $(GLUCOSE_OBJECTS) $(MAIN_OBJECT)
	$(CXX) -o $(EXECUTABLE_SOLID) $(MAIN_OBJECT) $(GLUCOSE_OBJECTS) $(LIB_OBJECTS) $(EXT_LIBS)
	$(LDD) $(EXECUTABLE_SOLID)
	$(STRIP) $(EXECUTABLE_SOLID)

$(OBJ)/%.d: src/%.cpp include/*.h
	@mkdir -p $(BASEDIR)/$(OBJ)
	@$(CXX) $(CXXFLAGS) -MM $< -MT $(@:.d=.o) -MF $@

$(OBJ)/%.o: src/%.cpp
	@mkdir -p $(BASEDIR)/$(OBJ)
	$(CXX) $(CXXFLAGS) -o $@ -c src/$*.cpp

$(OBJ)/glucose/%.o: $(GLUCOSE)/core/%.cc
	@mkdir -p $(OBJ)/glucose
	$(CXX) $(CXXFLAGS) -o $@ -c $(GLUCOSE)/core/$*.cc

clean:
	$(RMRF) $(OBJ_DIR)
	$(RMRF) $(SHARED_LIB)
	$(RMRF) $(EXECUTABLE_SOLID)
	$(RMRF) $(EXECUTABLE_LIB)

# include dependencies to this makefile
-include $(LIB_DEPENDS)
