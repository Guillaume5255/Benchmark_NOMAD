ifndef ($(VARIANT))
VARIANT             = release
endif

UNAME := $(shell uname)
#$(shell pwd | sed 's/\/examples.*//')
#nomad.4.0.0 and Benchmark_NOMAD must be in the same directory 
NOMAD_DIR	= $(shell pwd | sed 's/\/Benchmark_NOMAD\/src*//')/nomad.4.0.0
PB_DIR_NAME	= problems
PB_DIR		= $(shell pwd)/$(PB_DIR_NAME)
BUILD_DIR	= $(NOMAD_DIR)/build/$(VARIANT)
SRC_DIR		= $(NOMAD_DIR)/src
OBJ_DIR		= $(BUILD_DIR)/obj
INCLUDE_DIR	= $(BUILD_DIR)/include
LIB_DIR		= $(BUILD_DIR)/lib
BIN_DIR		= $(BUILD_DIR)/bin
EXE		= $(BIN_DIR)/benchmark.exe
BENCHMARKER	= benchmarker.exe
BENCHMARKER_SCRIPT = benchmarkJobs.sh

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
CXXFLAGS	= -O2
else
CXXFLAGS	= -g -DDEBUG
endif



CXXFLAGS	+= -std=c++14 -Wall -fpic
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
RUN_DIR		= ../run
endif

#$(LIB_DYNAMIC)	
buildBenchmarker: $(INCLUDE_DIR) $(OBJ_DIR) benchmark.cpp buildBlackbox script
	$(COMPILE) -o $(RUN_DIR)/$(BENCHMARKER) benchmark.cpp $(PB_DIR_NAME)/blackbox.o $(LIB_DYNAMIC)
	
buildBlackbox: $(PB_DIR_NAME)/blackbox.cpp $(PB_DIR_NAME)/blackbox.hpp
	$(COMPILE_BB) -o $(PB_DIR_NAME)/blackbox.o $(PB_DIR_NAME)/blackbox.cpp
	
init:
	mkdir $(RUN_DIR)

script:
	cp $(BENCHMARKER_SCRIPT) $(RUN_DIR)
	
clean: cleanBBDir cleanRunDir cleanBenchmarker cleanScript

cleanScript:
	rm -f $(RUN_DIR)/$(BENCHMARKER_SCRIPT)

cleanBBDir:
	rm -f $(PB_DIR_NAME)/blackbox.o

cleanRunDir:
	rm -f $(RUN_DIR)/run*
	
cleanBenchmarker:
	rm -f $(RUN_DIR)/$(BENCHMARKER)
