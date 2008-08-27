#include <stdlib.h>
#include <stdio.h>
#include <xlocale.h>
#include <stdarg.h>
#include <unistd.h>
#include <string.h>

struct list {
    struct hash* columns;
    int   numColumns;
};
struct hash {
    char value[40];
};

int main() {
    srandomdev();
    
    int i = 0; struct list* last;
    int num = atoi("8000000");
    
    int size = 1000;
    /* Initialize initial list of revisions */
    struct list** revisionList = malloc(size * sizeof(struct list*));

    struct hash standardColumn;
    strcpy(standardColumn.value, "Haha pieter");
    for (i = 0; i < num; i++) {
        if (size <= i) {
            size *= 2;
            revisionList = realloc(revisionList, size * sizeof(struct list*));
        }

	struct list* a = malloc(sizeof(struct list));
	revisionList[i] = a;

        a->numColumns = i % 5;
	a->columns = malloc(a->numColumns * sizeof(struct hash));
        int j;
        for (j = 0; j < a->numColumns; j++) {
            //ccolumns[currentColumn++] = st
            strncpy(a->columns[j].value, "Haha pieter is cool", 20);
        }
    }
    
    printf("Num value at 3000 is: %i vs %i\n", revisionList[3000]->numColumns, (int) (5 * random()));
    return 0;
}