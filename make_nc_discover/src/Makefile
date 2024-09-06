CC = mpicc -O2 

INCLUDE = -I$(GDAL_INC) 
LIBRARY = -L$(GDAL_LIB) -lgdal -lm

FILES  = write_netcdf.o sendReceiveData.o read_vrts.o
BIN = ../bin

.SUFFIXES: $(SUFFIXES) .c

%.o : %.c
	$(CC) $(INCLUDE) -c $<

reproject: $(FILES) 
	$(CC) $(INCLUDE) $(FILES) $(LIBRARY) -o $(BIN)/make_vrts.exe
clean: 
	/bin/rm $(BIN)/make_vrts.exe *.o

