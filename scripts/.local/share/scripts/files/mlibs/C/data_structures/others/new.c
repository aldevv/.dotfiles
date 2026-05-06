#include <stdio.h>
#include <hash_table.h>
 
int main(void) {
    hashtable_t* ht = create_hashtable();
    ht_set(ht, "name1", "em");
    ht_set(ht, "name2", "russian");
    ht_set(ht, "name3", "pizza");
    ht_set(ht, "name4", "doge");
    ht_set(ht, "name5", "pyro");
    ht_set(ht, "name6", "joost");
    ht_set(ht, "name7", "kalix");
    // printf("\n%s\n",ht->bucket[4]->value);
    char* name = ht_get(ht,"name4");
    ht_show(ht);
    printf("\n%s\n",name);

}