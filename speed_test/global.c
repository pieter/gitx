#include <stdlib.h>
#include <stdio.h>
#include <xlocale.h>
#include <stdarg.h>
#include <unistd.h>
#include <string.h>
struct list {
    void* columns;
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
    int totColumns = 10000;
    int currentColumn = 0;

    /* Initialize initial list of revisions */
    struct list* revisionList = malloc(size * sizeof(struct list));
    struct hash* columns = malloc(totColumns * sizeof(struct hash));

    struct hash standardColumn;
    strcpy(standardColumn.value, "Haha pieter");
    for (i = 0; i < num; i++) {
        if (size <= i) {
            size *= 2;
            revisionList = realloc(revisionList, size * sizeof(struct list));
        }
            
        struct list* a = revisionList + i;
        a->numColumns = i % 5;
        if (currentColumn + a->numColumns > totColumns) {
            totColumns *= 2;
            printf("Reallocing columns. New total: %i\n", totColumns);
            columns = realloc(columns, totColumns * sizeof(struct hash));
        }
        int j;
        for (j = 0; j < a->numColumns; j++) {
            //ccolumns[currentColumn++] = st
            strncpy(columns[currentColumn++].value, "Haha pieter is cool", 20);
        }
    }
    
    printf("Num value at 3000 is: %i vs %i\n", revisionList[3000].numColumns, (int) (5 * random()));
    printf("Value of 1000'd column is: %s\n", columns[1000].value);
    sleep(5);
    return 0;
}