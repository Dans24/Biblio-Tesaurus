%{
 #define _GNU_SOURCE
 #include <stdio.h>
 int yyerror(char *s){ fprintf(stderr,"Erro: %s\n",s);}
 int yylex();
 #include <gmodule.h>
 GHashTable *linguas;
 GList *relacoes;
 
 char *baselang;
 typedef struct pair{
      void* a1;
      void* a2;
 } *Pair;
 
 typedef char* String;

 typedef struct conceito{
      String termobase;
      GList *ligacoes;
 }    *Conceito;
%}


%token  HEAD STRING LING REL LANGUAGE BASELANG INV SCOPENOTE;
%union{ 
      char* s;
      GList *list;
      Pair par;
      Conceito c;
      }

%type <s> HEAD STRING LING REL 
%type <list> termos conceitos  ligacoes
%type <c> conceito
%%

thesaurus   : metadados '\n' conceitos
            |
            ;

metadados   : metadado '\n' metadados 
            |
            ;

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
            
conceitos   : conceito '\n' conceitos        {$$ = g_list_prepend($3,$1);}
            | conceito                       {$$ = g_list_prepend(NULL,$1);}
            |                                   {$$ = NULL;}            
            ;

conceito    :     STRING ligacoes   {
                                          Conceito c = malloc(sizeof(struct conceito));
                                          c->termobase = $1;
                                          c->ligacoes = $2;
                                          $$ = c;
                                    }
            ;

      /* 1ª elemento identificador 2º elemento termos */
ligacoes    : '\n' STRING termos ligacoes       {
                                                      //Código para escrever coisas
                                                      Pair p = malloc(sizeof(struct pair));
                                                      p->a1 = $2;
                                                      p->a2 = $3;
                                                      $$ = g_list_prepend($4,p);
                                                };
            /*TODO: Adicionar SCOPENOTE*/
            |  '\n'                             {$$ = NULL;}      /*Para o caso em que n tem linhas*/
            ;
          
termos      : STRING    {$$ = g_list_prepend(NULL,$1);}
            | STRING ',' termos     {$$ = g_list_prepend($3,$1);}
            | STRING ',' '\n' termos     {$$ = g_list_prepend($4,$1);}
            ;



%%
 #include "lex.yy.c"
int main(){
   relacoes = NULL;
   linguas = g_hash_table_new(g_str_hash,NULL);
   yyparse();
   return 0;
}
