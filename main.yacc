%{
 #define _GNU_SOURCE
 #include <stdio.h>
 int yylex();
 #include <gmodule.h>
 GHashTable *linguas;
 GList *relacoes;
 int yyerror(char *s);
 char *baselang;
 typedef struct pair{
      void* a1;
      void* a2;
 } *Pair;
 
 typedef char* String;

 typedef struct conceito{
      String termobase;
      GHashTable *traducoes; //Hash table com chave(Def) e Valor Lista de Termos 
      GHashTable *ligacoes; //Hash table com chave(Def) e Valor Lista de Termos 
 }    *Conceito;
%}


%token  HEAD STRING LING REL LANGUAGE BASELANG INV LINEBREAK;
%union{ 
      char* s;
      GList *list;
      GHashTable *hash;
      Pair par;
      Conceito c;
      }

%type <s> HEAD STRING LING REL 
%type <list> termos conceitos note list     
%type <par> ligacoes
%type <c> conceito
%%
      /*Axioma:*/
thesaurus   : metadados '\n' conceitos    {
                                                //Código para escrever coisas;
                                                //Conceitos é uma lista com Conceito
                                                GHashTableIter iter;
                                                gpointer key, value;

                                                g_hash_table_iter_init (&iter, linguas);
                                                while (g_hash_table_iter_next (&iter, &key, &value)) {
                                                      printf("%s %s\n", (char *) key, (char *) value);
                                                }

                                                for (GList* l = relacoes; l != NULL; l = l->next) {
                                                      Pair data = (Pair) l->data;
                                                      printf("%s %s\n", (char*) data->a1, (char*) data->a2);
                                                }

                                                for (GList* l = $3; l != NULL; l = l->next) {
                                                      Conceito data = (Conceito) l->data;
                                                      printf("Termo Base: %s\n", (char*) data->termobase);
                                                      g_hash_table_iter_init (&iter, data->traducoes);
                                                      while (g_hash_table_iter_next (&iter, &key, &value)) {
                                                            printf("Tradução: %s %s\n", (char *) key, (char *) value);
                                                      }
                                                      g_hash_table_iter_init (&iter, data->traducoes);
                                                      while (g_hash_table_iter_next (&iter, &key, &value)) {
                                                            for (GList* l = value; l != NULL; l = l->next) {
                                                                  printf("Ligações: %s %s\n", (char *) key, (char *) value);
                                                            }
                                                      }
                                                      for (GList* l = data->scopenote; l != NULL; l = l->next) {
                                                            char* data = l->data;
                                                            printf("Nota: %s\n", data);
                                                      }
                                                      printf("\n");
                                                }
                                          }
            |
            ;

metadados   : metadado '\n' metadados 
            |
            ;

            /*Metadados:  */
metadado    : LANGUAGE linguas            
            | BASELANG STRING             {baselang = $2;}
            | INV STRING STRING           {
                                                Pair par= malloc(sizeof(struct pair));
                                                par->a1 = $2;
                                                par->a2 = $3;
                                                relacoes = g_list_prepend(relacoes,par);
                                          }
            ;

linguas     : STRING {g_hash_table_add(linguas,$1);} linguas
            |           {}
            ;
            
conceitos   : conceito conceitos          {$$ = g_list_prepend($2,$1);}
            | '\n' conceitos              {$$ = $2;}            
            |                             {$$ = NULL;}            
            ;

conceito    :     '\n' STRING '\n' ligacoes {
                                          Conceito c = malloc(sizeof(struct conceito));
                                          c->termobase = $2;
                                          c->traducoes = $4->a1;
                                          c->ligacoes = $4->a2;
                                          $$ = c;
                                    }
            ;

      /* 1ª elemento identificador 2º elemento termos */
      /* Par de Hash's primeira com as traduções, segunda com as relações Hashes são chave->lista*/
ligacoes    : STRING list '\n' ligacoes         {
                                                      //Código para escrever coisas
                                                      GHashTable* hash;
                                                      if(g_hash_table_contains(linguas,$1))
                                                            hash = $4->a1;    //Hash das Linguas
                                                      else 
                                                            hash = $4->a2;    //Hash dos termos 
                                                      GList* termos = g_hash_table_lookup(hash,$1);
                                                      termos = g_list_concat(termos,$2);
                                                      g_hash_table_replace(hash,$1,termos);
                                                      $$ = $4;
                                                }
            |                                  {
                                                      Pair p = malloc(sizeof(struct pair));
                                                      p->a1 = g_hash_table_new(g_str_hash,g_str_equal); 
                                                      p->a2 = g_hash_table_new(g_str_hash,g_str_equal); 
                                                      $$ = p;
                                                }      /*Para o caso em que n tem linhas*/
            ;


list        : STRING note                  {$$ = g_list_prepend($2,$1);}
            | STRING termos                {$$ = g_list_prepend($2,$1);}
            ;

note        : STRING note                 {
                                                $$ = g_list_prepend($2,$1);
                                          }
            | LINEBREAK STRING note            {
                                                $$ = g_list_prepend($3,$2);
                                          }
            |                             {$$ = NULL;}
            ;
            
termos      : ',' STRING    {$$ = g_list_prepend(NULL,$2);}
            | ',' LINEBREAK STRING      {$$ = g_list_prepend(NULL,$3);}            
            | ',' STRING termos     {$$ = g_list_prepend($3,$2);}
            | ',' LINEBREAK STRING termos     {$$ = g_list_prepend($4,$3);}
            ;



%%
#include "lex.yy.c"
int yyerror(char *s){ fprintf(stderr,"Erro: %s at line %d: %s \n",s,yylineno,yytext);}

int main(){
   relacoes = NULL;
   linguas = g_hash_table_new(g_str_hash,g_str_equal);
   yyparse();
   return 0;
}
