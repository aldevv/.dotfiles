#include <stdio.h>
#include <stdlib.h>

typedef struct tag
{
    struct tag* left;
    struct tag* right;
    int data;
}tree;

tree* root = NULL;

tree*
create_node(int data)
{
    tree* node = (tree*) malloc(sizeof(tree*));
    node->data = data;
    node->left = NULL;
    node->right = NULL;
    return node;

}

void 
insert_tree(int data)
{
    tree* node;

    if(root == NULL)
    {

       node = (tree*)malloc(sizeof(tree*));
       node->data = data; 
       node->left = NULL;
       node->right = NULL;
       root = node;
       return;
    }
    tree* prev = (tree*)malloc(sizeof(tree*));
    node = root;
    while(node != NULL)
    {
        prev = node;
        if(data < node->data)
        {
            node = node->left;
            continue;
        }
        if(data > node->data)
        {
            node = node->right;
            continue;
        }
    }
    node = (tree*)malloc(sizeof(tree*));
    node->data = data;
    node->left = NULL;
    node->right = NULL;
    if(data < prev->data)  
        prev->left = node;
    else
        prev->right = node;
}
void
showTree(tree* mytree)
{
    if(mytree != NULL)
    {
        printf("%d\n",mytree->data);
        showTree(mytree->left);
        showTree(mytree->right);
    }
}
int
getHeight(tree* mytree)
{
    if(mytree == NULL)
        return 0;
    int left = getHeight(mytree->left);
    int right = getHeight(mytree->left);
    if(left > right)    
        return left +1;
    else
        return right + 1;
    
}
int
main(void)
//! all works!
{
    // root = create_node(10);
    // root->left = create_node(5);
    // root->right = create_node(12);
    // root->left->left = create_node(3);
    // root->left->left->left = create_node(1);
    // root->left->left->right = create_node(4);
    // root->left->right = create_node(7);
    // root->left->right->right = create_node(8);
    // root = create_node(10);
    insert_tree(10);
    insert_tree(5);
    insert_tree(3);
    insert_tree(12);
    insert_tree(4);
    // showTree(root);
    // printf("%d",getHeight(root));
    
}