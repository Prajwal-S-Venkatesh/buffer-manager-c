# Set the compiler and compiler flags
CC = gcc
# -g adds debugging information to the executable file while -Wall enables all the warnings
CFLAGS  = -g -Wall

# Run clean, build and tests in one go!
run: clean all run_test_1 run_test_2
	make clean
 
# The build target executable:
all: test_1 test_2

# To create the executable file
test_1: test_assign2_1.o storage_mgr.o dberror.o buffer_mgr.o buffer_mgr_stat.o
	$(CC) $(CFLAGS) -o test_1 test_assign2_1.o storage_mgr.o dberror.o buffer_mgr.o buffer_mgr_stat.o -lm

# To create the executable file
test_2: test_assign2_2.o storage_mgr.o dberror.o buffer_mgr.o buffer_mgr_stat.o
	$(CC) $(CFLAGS) -o test_2 test_assign2_2.o storage_mgr.o dberror.o buffer_mgr.o buffer_mgr_stat.o -lm

# To create the object file
test_assign2_1.o: test_assign2_1.c dberror.h storage_mgr.h test_helper.h buffer_mgr.h buffer_mgr_stat.h
	$(CC) $(CFLAGS) -c test_assign2_1.c -lm

# To create the object file
test_assign2_2.o: test_assign2_2.c dberror.h storage_mgr.h test_helper.h buffer_mgr.h buffer_mgr_stat.h
	$(CC) $(CFLAGS) -c test_assign2_2.c -lm

# To create the object file
buffer_mgr_stat.o: buffer_mgr_stat.c buffer_mgr_stat.h buffer_mgr.h
	$(CC) $(CFLAGS) -c buffer_mgr_stat.c

# To create the object file
buffer_mgr.o: buffer_mgr.c buffer_mgr.h dt.h storage_mgr.h
	$(CC) $(CFLAGS) -c buffer_mgr.c

# To create the object file
buffer_mgr_helper.o: buffer_mgr.h storage_mgr.h 
	$(CC) $(CFLAGS) -c buffer_mgr_helper.c -lm

storage_mgr.o: storage_mgr.c helper.c storage_mgr.h 
	$(CC) $(CFLAGS) -c storage_mgr.c -lm

helper.o: helper.c storage_mgr.h 
	$(CC) $(CFLAGS) -c helper.c -lm

# To create the object file
dberror.o: dberror.c dberror.h 
	$(CC) $(CFLAGS) -c dberror.c

# To remove generated files
clean: 
	$(RM) test_1 test_2 *.o *~ *.bin

# Run the test_1
run_test_1:
	./test_1

# Run the test_2
run_test_2:
	./test_2