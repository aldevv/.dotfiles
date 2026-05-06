#include <stdio.h>
#include <iostream>
#include <math.h>
using namespace std;

//!https://www.hackerearth.com/practice/data-structures/advanced-data-structures/segment-trees/tutorial/
void
showArray(int* array, int n)
{
    for(int i=0; i<n; i++)
       printf("%3d",array[i]);
    printf("\n");
}
int
max_num_leaves(int n)
{
    int height = ceil(log2(n));
    int max_num_leaves = (2 * (pow(2,height))) -1;
    return max_num_leaves;
}

int*
create_segment_tree(int n)
{
    int* tree = (int*) malloc(sizeof(int*)*max_num_leaves(n));
    return tree;
}

int
min (int a, int b) {return a<b ? a: b;}

void
fill_tree(int* tree, int array[], int i, int start, int end)
{
    if(start == end)
    {
        // Leaf node will have a single element
        tree[i] = array[start];
        return;
    }
    int mid = (start + end) / 2;
    // Recurse on the left child
    fill_tree(tree,array,2*i+1, start, mid);
    // Recurse on the right child
    fill_tree(tree,array,2*i+2, mid+1, end);
    // Internal node will have the sum of both of its children
    tree[i] = tree[2*i+1] + tree[2*i+2];
}

struct tree
{
    int val;
    struct tree* left;
    struct tree* right;
};
// same as fill tree
struct tree* 
create_segment_tree(int* arr, int start,int end)
{
    struct tree* root = new struct tree;
    if(start == end)
    {
         root->val = arr[start];
         return root;
    }
    int middle  = start + (end-start)/ 2;
    root->left  = create_segment_tree(arr, start, middle);
    root->right = create_segment_tree(arr, middle+1, end);
    root->val = root->left->val + root->right->val;
    return root;
} 
 
void
show_tree(struct tree* mytree)
{
    if(mytree == nullptr)
        return;
    show_tree(mytree->left);
    cout << mytree->val << "\n";
    show_tree(mytree->right);
}
int
main(void)
{
    ios_base::sync_with_stdio(false);
    int array[5] = {2,-3,-3,-3,2};
    int* st = create_segment_tree(5);
    fill_tree(st,array,0,0,4);
    showArray(st,max_num_leaves(5));
}