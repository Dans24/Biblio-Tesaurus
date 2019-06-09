%{
 #define _GNU_SOURCE
 #include <stdio.h>
 int yylex();
 #include <gmodule.h>
 GHashTable *linguas;
 GHashTable *description;
 GHashTable *externs; //deve ser interpretado como texto
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
 void printPostIndex(FILE* f);
 void printPreIndex(FILE* f);
%}


%token  HEAD STRING LING REL LANGUAGE EXTERN DESC BASELANG INV LINEBREAK;
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
thesaurus   : metadados  conceitos        {
                                                //Código para escrever coisas;
                                                //Conceitos é uma lista com Conceito
                                                GHashTableIter iter;
                                                gpointer key, value;
                                                FILE * indexF;
                                                indexF = fopen("index.html","w");
                                                printPreIndex(indexF);
                                                
                                                g_hash_table_iter_init (&iter, linguas);
                                                while (g_hash_table_iter_next (&iter, &key, &value)) {
                                                      printf("%s %s\n", (char *) key, (char *) value);
                                                }

                                                for (GList* l = relacoes; l != NULL; l = l->next) {
                                                      Pair data = (Pair) l->data;
                                                      printf("%s %s\n", (char*) data->a1, (char*) data->a2);
                                                }

                                                for (GList* l = $2; l != NULL; l = l->next) {
                                                      Conceito data = (Conceito) l->data;
                                                      fprintf(indexF,"\n<option>%s</option>",data->termobase);
                                                      char filepath[200] = {0}; strcat(filepath,data->termobase);strcat(filepath,".html");
                                                      FILE* page = fopen(filepath,"w");
                                                      
                                                      fprintf(page,"<h1>%s</h1>",data->termobase);

                                                      g_hash_table_iter_init (&iter, data->traducoes);
                                                      while (g_hash_table_iter_next (&iter, &key, &value)) {
                                                            char * keyName =  g_hash_table_lookup(description,key);
                                                            if(keyName == NULL)
                                                                  keyName = (char *) key;
                                                            fprintf(page,"<p>Tradução: %s %s</p>\n", keyName, (char *)((GList*)value)->data);
                                                      }
                                                      g_hash_table_iter_init (&iter, data->ligacoes);
                                                      while (g_hash_table_iter_next (&iter, &key, &value)) {
                                                            char * keyName =  g_hash_table_lookup(description,key);
                                                            if(keyName == NULL)
                                                                  keyName = (char *) key;
                                                            if(g_hash_table_contains(externs,key)){
                                                                  fprintf(page,"<p>%s: %s",keyName, (char *)((GList*)value)->data);
                                                                  for (GList* l = ((GList*)value)->next; l != NULL; l = l->next) {
                                                                        fprintf(page," %s", (char*)l->data);
                                                                  }
                                                                  fprintf(page,"</p>\n");
                                                            }
                                                            else
                                                                  for (GList* l = value; l != NULL; l = l->next) {
                                                                        fprintf(page,"<p>Ligações: %s %s</p>\n", keyName, (char *) l->data);
                                                                  }
                                                      }
                                                      fclose(page);
                                                }
                                                printPostIndex(indexF);
                                          }
            |
            ;

metadados   : metadado '\n' metadados 
            | '\n'
            ;

            /*Metadados:  */
metadado    : LANGUAGE linguas            
            | BASELANG STRING             {baselang = $2;}
            | EXTERN  STRING              {g_hash_table_add(externs,$2);}
            | DESC STRING STRING                {g_hash_table_replace(description,$2,$3);}
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
            
conceitos   : conceito '\n' conceitos          {$$ = g_list_prepend($3,$1);}
            | '\n' conceitos              {$$ = $2;}            
            |                             {$$ = NULL;}            
            ;

conceito    :     STRING '\n' ligacoes {
                                          Conceito c = malloc(sizeof(struct conceito));
                                          c->termobase = $1;
                                          c->traducoes = $3->a1;
                                          c->ligacoes = $3->a2;
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
                                                      termos = g_list_concat($2,termos);
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


void printPreIndex(FILE* f){
      fprintf(f,"<head><meta charset=\"utf-8\" name=\"viewport\" content=\"width=device-width, initial-scale=1, shrink-to-fit=no\"><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css\" integrity=\"sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm\" crossorigin=\"anonymous\"><script src=\"https://code.jquery.com/jquery-1.10.2.js\"></script><title>Biblio-Thesarus</title></head><script>$( document ).ready(function() {$( \"#stuff\" ).change(function (){$(\"#frame\").attr(\"src\",$(this).val()+\".html\");});});</script>");
      fprintf(f,"<div class=\"container\"><div><h1>Biblio-Thesarus</h1><select id=\"stuff\" class=\"form-control\" data-show-subtext=\"true\" data-live-search=\"true\">");
}

void printPostIndex(FILE* f){
      fprintf(f,"</select></div><br/><div class=\"embed-responsive embed-responsive-16by9\"><iframe id=\"frame\" class=\"embed-responsive-item\" src=\"\" allowfullscreen></iframe></div></div>");
      fclose(f);
}

int main(){
   relacoes = NULL;
   linguas = g_hash_table_new(g_str_hash,g_str_equal);
   description = g_hash_table_new(g_str_hash,g_str_equal);
   externs = g_hash_table_new(g_str_hash,g_str_equal);
   g_hash_table_add(externs,"SN");
   yyparse();
   return 0;
}
