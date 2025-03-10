VPATH = .:RCS:TMP

.SUFFIXES: .o .F90 .F

include ../Make.Inc/make.inc

LIBS += -L../../lib/ -lhycnersc
INCLUDE += -I../../include/

# Compiler rules
%.o: %.F90
	$(CF90) -c $(CPPFLAGS) $(FFLAGS) $(F90FLG) $(INCLUDE) -o $@ $<

%.o: %.F
	$(CF77) -c $(CPPFLAGS) $(FFLAGS) $(F77FLG) $(INCLUDE) -o $@ $<

# Targets
TARGETS = get_meanssh get_depths get_config

all: $(TARGETS)

# Object files
OBJS = m_io_hycom.o m_io_direct.o m_io_binary.o m_get_mod_cnfg.o qmpi.o

get_meanssh_OBJS = get_meanssh.o $(OBJS)
get_depths_OBJS = get_depths.o $(OBJS)
get_config_OBJS = get_config.o $(OBJS)

get_meanssh: $(get_meanssh_OBJS)
	$(LD) $(LINKFLAGS) -o $@ $(get_meanssh_OBJS) $(LIBS)

get_depths: $(get_depths_OBJS)
	$(LD) $(LINKFLAGS) -o $@ $(get_depths_OBJS) $(LIBS)

get_config: $(get_config_OBJS)
	$(LD) $(LINKFLAGS) -o $@ $(get_config_OBJS) $(LIBS)

# Dependencies

get_depths.o: get_depths.F90 $(OBJS)

get_config.o: get_config.F90 $(OBJS)

get_meanssh.o: get_meanssh.F90 $(OBJS)

m_get_mod_cnfg.o: m_get_mod_cnfg.F90 m_io_hycom.o qmpi.o

m_io_hycom.o: m_io_hycom.F90

m_io_direct.o: m_io_direct.F90

m_io_binary.o: m_io_binary.F90

qmpi.o: qmpi.F90

# Clean rule
clean:
	rm -f *.o *.mod *.f *.f90 $(TARGETS)
