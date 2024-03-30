
CC = gcc
FLAGS = -I ./NtyCo/core/ -L ./NtyCo/ -lntyco
SRCS = kvstore.c reactor_entry.c kvstore_array.c ntyco_entry.c kvstore_rbtree.c kvstore_hash.c
TARGET = kvstore
TESTCASE_SRCS = testcase.c
TESTCASE = testcase

OBJDIR = obj
OBJS = $(SRCS:%.c=$(OBJDIR)/%.o)

all: $(TARGET) $(TESTCASE)

$(OBJDIR)/%.o: %.c
	@mkdir -p $(OBJDIR)
	$(CC) -o $@ -c $< $(FLAGS)

$(TARGET): $(OBJS)
	$(CC) -o $@ $^ $(FLAGS)

$(TESTCASE): $(TESTCASE_SRCS)
	$(CC) -o $@ $^


%.o: %.c
	$(CC) $(FLAGS) -c $^ -o $@

clean:
	rm -rf $(OBJDIR) $(TARGET) $(TESTCASE)