#include <stdlib.h>
#include <stdio.h>
#include <xlocale.h>
#include <stdarg.h>
#include <unistd.h>
#include <string.h>
#include <Cocoa/Cocoa.h>

int main() {
    srandomdev();
    
    int i = 0; struct list* last;
    int num = atoi("8000000");
    
    int size = 1000;
    int totColumns = 10000;
    int currentColumn = 0;

    NSMutableArray* array = [NSMutableArray arrayWithCapacity: 100*size];

    for (i = 0; i < num; i++) {
        int numColumns = i % 5;
        
        NSMutableArray* arr = [NSMutableArray arrayWithCapacity: numColumns];
        int j;
        for (j = 0; j < numColumns; j++)
            [arr addObject: @"Ha"];
        [array addObject: arr];
    }

    [array release];
    return 0;
}