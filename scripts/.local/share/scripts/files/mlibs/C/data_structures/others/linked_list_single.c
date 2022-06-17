#include <stdio.h>
#include <stdlib.h>
#include "linked_list_single.h"
 
Node* head = NULL;

void
add_at(int value, int pos)
{
    Node* node = (Node*) malloc(sizeof(Node*));
    node->data = value;
    Node* current = head;
    Node* previous;
    int index = 0;

    if(current == NULL)    {node->next = NULL; head = node; return;}
        

    while(current->next != NULL && index != pos)
    {
        index++;
        previous = current;
        current = current->next;
    }

    // * got to the end
    if(current->next == NULL)
    {
        node->next = NULL;
        current->next = node;
        // printf("%d with: %p\n",current->data,current->next);
        return;
    }

    // * beggining 
    if(index == 0)
    {
        node->next = head;
        head = node;
        return;
    }

    // got to position
    previous->next = node;
    node->next = current;
    return;
}
void
add_beg(int value)
{
    add_at(value,0);
}

void 
add_end(int value)
{
    add_at(value,-1);
}


Node*
search_linked_list(int value)
{
    Node* mynode = head;
    while(mynode != NULL && mynode->data != value)
    {
        mynode = mynode->next;
    }
    return mynode; //! returns NULL if not found 
}

void
remove_node(int value)
{
    Node* mynode = head;
    if(mynode->data == value)   {head = mynode->next;return;}
    Node* prev;
    while(mynode->next != NULL && mynode->data != value)
    {
        prev = mynode;
        mynode = mynode->next;
    }
    if(mynode->next == NULL && mynode->data != value)   return;

    prev->next = mynode->next;
    free(mynode);
}

void
showLL()
{
    Node* node = head;
    while(node != NULL)
    {
        printf("%d, next=%p\n",node->data,node->next);
        node = node->next;
    }
}

int
main(void) {

    // add_end(4);
    // add_end(5);
    add_at(11,-1);
    add_at(4,0);
    add_beg(1);
    add_end(18);
    add_beg(3);
    add_end(6);
    add_at(13,5);
    remove_node(13);
    showLL();
 
}