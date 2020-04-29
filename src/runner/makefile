ifndef ($(VARIANT))
VARIANT             = release
endif

UNAME := $(shell uname)
#$(shell pwd | sed 's/\/examples.*//')
ROOT_DIR	= $(shell pwd | sed 's/\/src\/runner*//')
NOMAD_DIR	= $(shell pwd | sed 's/\/Benchmark_NOMAD\/src\/runner*//')/nomad
PB_DIR		= $(ROOT_DIR)/src/problems
BUILD_DIR	= $(NOMAD_DIR)/build/$(VARIANT)
SRC_DIR		= $(NOMAD_DIR)/src
OBJ_DIR		= $(BUILD_DIR)/obj
INCLUDE_DIR	= $(BUILD_DIR)/include
LIB_DIR		= $(BUILD_DIR)/lib
BIN_DIR		= $(BUILD_DIR)/bin
#EXE			= $(BIN_DIR)/benchmark.exe
ifndef RUNNER_SOURCE
RUNNER_SOURCE = benchmark.cpp
endif

RUNNER	= benchmarker.exe
RUNNER_SCRIPT = benchmarkJobs.sh

UTILS_LIB_CURRENT_VERSION = 4.0.0
EVAL_LIB_CURRENT_VERSION = 4.0.0
ALGOS_LIB_CURRENT_VERSION = 4.0.0

UTILS_NAME_AND_VERSION	= nomadUtils.$(UTILS_LIB_CURRENT_VERSION)
EVAL_NAME_AND_VERSION	= nomadEval.$(EVAL_LIB_CURRENT_VERSION)
ALGOS_NAME_AND_VERSION	= nomadAlgos.$(ALGOS_LIB_CURRENT_VERSION)

#SGTE_LIB_DYNAMIC	  = $(LIB_DIR)/libsgtelib.so


LIB_DYNAMIC		= -l$(UTILS_NAME_AND_VERSION) -l$(EVAL_NAME_AND_VERSION) -l$(ALGOS_NAME_AND_VERSION)
# $(SGTE_LIB_DYNAMIC)

CXX =		g++

ifeq ($(VARIANT), release)
#CXXFLAGS	= -O2
else
CXXFLAGS	= -g -DDEBUG
endif



CXXFLAGS	= -std=c++14 -Wall -fpic
# Use OpenMP for parallelism (threads)
ifndef NOOMP
CXXFLAGS	+= -fopenmp
endif

CXXFLAGS	+= -L$(LIB_DIR)

ifeq ($(UNAME), Linux)
CXXFLAGS_LIBS = -Wl,-rpath,$(LIB_DIR) 
endif

INCLFLAGS	= -I$(INCLUDE_DIR)

COMPILE		= $(CXX) $(CXXFLAGS) $(INCLFLAGS) $(CXXFLAGS_LIBS)

COMPILE_BB	= $(CXX) -std=c++14 -Wall -fopenmp -c

ifndef ($(RUN_DIR))
RUN_DIR		= $(ROOT_DIR)/run
endif

#$(LIB_DYNAMIC)	
buildRunner: $(INCLUDE_DIR) $(OBJ_DIR) $(RUNNER_SOURCE) buildBlackbox
	$(COMPILE) -o $(RUN_DIR)/$(RUNNER) $(RUNNER_SOURCE) $(PB_DIR)/blackbox.o $(LIB_DYNAMIC)
	
buildBlackbox: $(PB_DIR)/blackbox.cpp $(PB_DIR)/blackbox.hpp
	$(COMPILE_BB) -o $(PB_DIR)/blackbox.o $(PB_DIR)/blackbox.cpp
	
init:
	mkdir $(RUN_DIR)

script:
	cp $(RUNNER_SCRIPT) $(RUN_DIR)
	
clean: cleanBBDir cleanRunDir cleanRunner

# cleanScript

#cleanScript:
#	rm -f $(RUN_DIR)/$(RUNNER_SCRIPT)

cleanBBDir:
	rm -f $(PB_DIR_NAME)/blackbox.o

cleanRunDir:
	rm -f $(RUN_DIR)/run*
	
cleanRunner:
	rm -f $(RUN_DIR)/$(RUNNER)
