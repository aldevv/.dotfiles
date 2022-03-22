#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
create_hashtable()
{
    hashtable_t* myht = malloc(sizeof(hashtable_t)); //needs to be a pointer so it can be returned
    myht->bucket = malloc(sizeof(entry_t*) * TABLE_SIZE);
    for(int i=0; i<TABLE_SIZE; i++)
        myht->bucket[i] = NULL;
    return myht;
}

int
hash_function(char* key) 
{
    int bucket = 0;
    for(int i =0,n =strlen(key); i<n; i++)
    {
        bucket += key[i]; //adds ascii values
    }
    bucket %= TABLE_SIZE;
    return bucket;
}
entry_t*
ht_input(entry_t* entry, char* key, char* value)
{
    entry = (entry_t*)malloc(sizeof(entry_t*));
    entry->key = (char*)malloc(strlen(key) + 1);
    entry->value = (char*)malloc(strlen(value) + 1);

    strcpy(entry->key,key);
    strcpy(entry->value,value);
    entry->next = NULL; //null now but can be set later

    return entry;
}

void
ht_set(hashtable_t* hashtable, char* key, char* value)
{
    int bucket_num = hash_function(key);
    // printf("original: for %s id: %d\n",key,bucket_num);
    entry_t* entry = hashtable->bucket[bucket_num]; //entry in the bucket with id: bucket_num
    if(entry == NULL) // if true then put the first entry
    {
        hashtable->bucket[bucket_num] = ht_input(entry,key,value); //puts the info into the entry in the corresponding bucket
        return;
    }
    entry_t* previous;

    while(entry != NULL)
    {
        if(strcmp(entry->key,key) == 0) //found key in bucket, replace value
        {
            free(entry->value);
            entry->value = (char*)malloc(strlen(value));
            strcpy(entry->value ,value);
            return;
        }
        previous = entry;
        entry = entry->next;
    }
    //end of bucket, add new entry
    previous->next = ht_input(entry,key,value);
}

char*
ht_get(hashtable_t* ht, char* key)
{
   //first find bucket 
   int bucket_num = hash_function(key);
   entry_t* entry =  ht->bucket[bucket_num];
   if(entry == NULL)
   {
    //    printf("entre");
        return NULL;
   }

    while(entry != NULL) 
    {
        if(strcmp(entry->key,key) == 0)
            return entry->value;
        entry = entry->next;
    }
    return NULL; //nothing found
}

void
ht_del(hashtable_t* hashtable, char* key)
{
    int bucket_num = hash_function(key);
    entry_t* entry = hashtable->bucket[bucket_num];

    if(entry == NULL)
        return;
    
    entry_t* previous;
    int index = 0;

    while(entry != NULL)
    {
        if(strcmp(entry->key,key) == 0)
        {
            if(entry->next == NULL && index == 0) // only 1 element
                hashtable->bucket[bucket_num] == NULL;
            if(entry->next != NULL && index == 0) // del first element
                hashtable->bucket[bucket_num] = entry->next;
            if(entry->next == NULL && index != 0) // last element
                previous->next = NULL;
            if(entry->next != NULL && index != 0)
                previous->next = entry->next; 

            free(entry->value);
            free(entry->key);
            free(entry);
            return;
        }
        previous = entry;
        entry = entry->next;
        index++;
    }
}

void 
ht_show(hashtable_t* hashtable) {
    for (int i = 0; i < TABLE_SIZE; ++i) {
        entry_t *entry = hashtable->bucket[i];

        if (entry == NULL) {
            continue;
        }

        printf("bucket[%4d]: ", i);

        while(1)
        {
            printf("%s=%s ", entry->key, entry->value);

            if (entry->next == NULL) 
                break;
            entry = entry->next;
        }
        printf("\n");
    }
}

// int main(void) {
//     hashtable_t* ht = create_hashtable();

//     ht_set(ht, "name1", "em");
//     ht_set(ht, "name2", "russian");
//     ht_set(ht, "name3", "pizza");
//     ht_set(ht, "name4", "doge");
//     ht_set(ht, "name5", "pyro");
//     ht_set(ht, "name6", "joost");
//     ht_set(ht, "name7", "kalix");
//     // printf("\n%s\n",ht->bucket[4]->value);
//     char* name = ht_get(ht,"name4");
//     ht_show(ht);
//     printf("\n%s\n",name);
// }