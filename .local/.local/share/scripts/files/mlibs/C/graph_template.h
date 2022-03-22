#ifndef GRAPH_H_
#define GRAPH_H_

#define NUM_NODES 6
typedef int Graph[NUM_NODES][NUM_NODES];

Graph def_graph = {
//   0  1    2    3   4    5
    0, 16,  13,  0,  0,  0, // 0
    0,  0,  10, 12,  0,  0, // 1
    0,  4,   0,  0, 14,  0, // 2
    0,  0,   9,  0,  0, 20, // 3
    0,  0,   0,  7,  0,  4, // 4
    0,  0,   0,  0,  0,  0, // 5
  };


#endif //FOO_H_
