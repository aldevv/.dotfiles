#ifndef HASH_TABLE
#define HASH_TABLE

typedef struct tag //linked list structure
{
    char* key;
    char* value;
    struct tag* next;
}entry_t;

typedef struct 
{
    entry_t** bucket;
}hashtable_t; 

void
ht_set(hashtable_t* hashtable, char* key, char* value);
hashtable_t*
create_hashtable();
char*
ht_get(hashtable_t* ht, char* key);
void
ht_del(hashtable_t* hashtable, char* key);
void
ht_show(hashtable_t* ht);

#endif 
