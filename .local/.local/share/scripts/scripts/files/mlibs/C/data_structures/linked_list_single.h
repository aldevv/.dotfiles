#ifndef LINKED_LIST
#define LINKED_LIST

typedef struct tag //have to use it because the compiler cant see the declaration from the inside
{
    int data;
    struct tag* next;
}Node;

void
add_at(int value, int pos);
void
add_beg(int value);
void 
add_end(int value);
Node*
search_linked_list(int value);
void
remove_node(int value);
#endif