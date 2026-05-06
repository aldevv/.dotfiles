#include <stdio.h>
#include <stdlib.h>

void showMatrix(int **matrix, int row, int col)
{
    for (int i = 0; i < row; i++)
    {
        for (int j = 0; j < col; j++)
        {
            printf("%4d", matrix[i][j]);
        }
        printf("\n");
    }
}

void readValues(int **matrix, int row, int col)
{
    for (int i = 0; i < row; i++)
        for (int j = 0; j < col; j++)
        {
            int value;
            printf("ingrese el valor para: [%d][%d]: ", i, j);
            scanf("%d", &value);
            matrix[i][j] = value;
        }
}
//!working 1
// void
// initMat(int* **matrix,int row, int col)
// {
//     int **temp;
//     temp = malloc(col * sizeof(int**));
//     for(int i=0;i<row;i++)
//         temp[i] = (int*)malloc(row * sizeof(int*));

//     *matrix = temp;
// }
//!working 2
void initMat(int ***matrix, int row, int col)
{
    *matrix = malloc(col * sizeof(int **));
    for (int i = 0; i < row; i++)
        (*matrix)[i] = (int *)malloc(row * sizeof(int *));
}
//!working 3
// void
// initMat(int* **matrix,int row, int col)
// {
//     *matrix = malloc(col * sizeof(int**));
//     for(int i=0;i<row;i++)
//         *((*matrix)+i) = (int*)malloc(row * sizeof(int*));
// }
int main(void)
{
    int **matrix;
    int row = 3, col = 3;
    initMat(&matrix, row, col);
    readValues(matrix, row, col);
    showMatrix(matrix, row, col);
}