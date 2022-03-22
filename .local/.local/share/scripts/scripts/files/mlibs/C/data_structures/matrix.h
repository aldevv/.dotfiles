#ifndef MATRIX_H
#define MATRIX_H
void 
showMatrix(int **mat, int n, int m);
void
getBounds(int *r, int *c);
int** 
createMatrix(int i, int n);
void 
fillMatrix(int **mat,int i, int n);
void
validate(int *n);
void
init_matrix_zeroes(int **mat, int r, int c);
#endif