#ifndef HASH_TABLE
#define HASH_TABLE
#define TABLE_SIZE 17  //should be prime to minimize collisions
//!https://www.youtube.com/watch?v=jEdaduyLLqY

typedef struct tag //linked list structure
{
    char* key;
    char* value;
    struct tag* next;
}entry_t;

typedef struct 
{
    entry_t** bucket;
}hashtable_t; // check if it needs to be a pointer

hashtable_t* 
create_hashtable();
void
ht_set(hashtable_t* hashtable, char* key, char* value);
char*
ht_get(hashtable_t* ht, char* key);
void
ht_del(hashtable_t* hashtable, char* key);
void 
ht_show(hashtable_t* hashtable);
#endif 
