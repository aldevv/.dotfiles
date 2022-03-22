#include <stdio.h>
#include <stdlib.h>

void showMatrix(int **mat, int n, int m){
    for(int i =0; i<n; i++) {
        for(int j=0; j<m; j++)
            printf("%3d",mat[i][j]);
        printf("\n");
    }
}
void
validate(int *n) {
    while(*n > 9 || *n < 0)
       scanf("wrong interval n", n); 
}
int** 
createMatrix(int i,int n) {
    // validate(&i);
    int **mat = (int **)malloc(i * sizeof(int*));
    for(int j = 0; j < n; j++) 
        mat[j] = (int *)malloc(n * sizeof(int));
    return mat;
}
void 
fillMatrix(int **mat,int i, int n) {
    for(int l=0; l<i; l++)
        for(int j=0;j<n;j++){
            // printf("ingrese la pos [%d] [%d]:",l,j);
            scanf("%d",&mat[l][j]);
        }
}

void
getBounds(int *r, int *c){
    scanf("%d",r);
    scanf("%d",c);
}

void
init_matrix_zeroes(int **mat, int r, int c) {
    for(int i =0; i< r; i++) 
        for(int j=0; j< c; j++)
            mat[i][j] = 0;
}
