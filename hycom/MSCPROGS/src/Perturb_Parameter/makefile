VPATH = .:TMP

.SUFFIXES:
.SUFFIXES: .o .F90 .F 

include ../Make.Inc/make.inc


# This is the hycom utility library
# NB: Path is relative to TMP dir. 
LIBS:= -L../../../lib/ -lhycnersc  $(LIBS) 

# This is the hycom utility includes (modules)
# NB: Path is relative to TMP dir
INCLUDE:= -I../../../include/  $(INCLUDE)

# AIX (xlf) peculiarities. NB: Only necessary for Fortran files
ifneq (,$(findstring -DAIX,$(CPPFLAGS)))
   subs=-WF,-
   CPPFLAGS:=$(subst -,$(subs),$(CPPFLAGS))
endif


# Rules for running cpp and updating files in TMP directory
.F90.o:
	cd ./TMP ; $(CF90) -c $(CPPFLAGS) $(FFLAGS) $(F90FLG) $(INCLUDE) -o $*.o ../$<

.F.o:
	cd ./TMP ; $(CF77) -c $(CPPFLAGS) $(FFLAGS) $(F77FLG) $(INCLUDE) -o $*.o ../$<



TARGET = init_param_bio
TARGET2 = ptrb_param_bio

all : $(TARGET) $(TARGET2)


#############################################################################
OBJECTS= \
			init_param_bio.o


$(TARGET): $(OBJECTS) 
	cd ./TMP ; $(LD) $(LINKFLAGS) -o ../$(TARGET) $(OBJECTS) $(LIBS) 
#############################################################################
#############################################################################
OBJECTS2= \
			ptrb_param_bio.o


$(TARGET2): $(OBJECTS2) 
	cd ./TMP ; $(LD) $(LINKFLAGS) -o ../$(TARGET2) $(OBJECTS2) $(LIBS) 
#############################################################################

install : all
	mkdir -p ../../bin
	cp $(TARGET) $(TARGET2) ../../bin/

clean:
	rm $(TARGET) $(TARGET2)
	cd ./TMP ; rm *.o *.mod
