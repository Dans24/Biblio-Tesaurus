%{
 #define _GNU_SOURCE
 #include <stdio.h>
 int yylex();
 #include <gmodule.h>
 GHashTable *linguas;
 GHashTable *description;
 GHashTable *externs; //deve ser interpretado como texto
 GTree *conceitos;
 GList *relacoes;
 int yyerror(char *s);
 char *baselang = NULL;
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
 void printHTML();
 gboolean printConceito(gpointer key, gpointer value, gpointer data);
 void printLigacao(FILE* page, gpointer key, gpointer value);
 gint strcmpG(gconstpointer a, gconstpointer b);
%}


%token  STRING LANGUAGE EXTERN DESC BASELANG INV LINEBREAK;
%union{ 
      char* s;
      GList *list;
      GHashTable *hash;
      Pair par;
      Conceito c;
      }

%type <s> STRING
%type <list> termos conceitos note list     
%type <par> ligacoes
%type <c> conceito
%%
      /*Axioma:*/
thesaurus   : metadados  conceitos        {
                                                printHTML();
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
            
conceitos   : conceito '\n' conceitos     {g_tree_insert (conceitos, (gpointer) $1->termobase, (gpointer) $1);}
            | '\n' conceitos              {}            
            |                             {conceitos = g_tree_new (strcmpG);}            
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
      fprintf(f,"<head><meta charset=\"utf-8\" name=\"viewport\" content=\"width=device-width, initial-scale=1, shrink-to-fit=no\"><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css\" integrity=\"sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm\" crossorigin=\"anonymous\"><script src=\"https://code.jquery.com/jquery-1.10.2.js\"></script><title>Biblio-Thesarus</title><script>$( document ).ready(function() {$( \"#stuff\" ).change(function (){$(\"#frame\").attr(\"src\",$(this).val()+\".html\");});});</script></head>");
      fprintf(f,"<div class=\"jumbotron\"><h1>Biblio-Thesarus");
      if(baselang) {
            gpointer baselangName = g_hash_table_lookup(description, (gpointer) baselang);
            if(baselangName) {
                  baselang = (char*) baselangName;
            }
            fprintf(f, "<small> (%s)</small>", baselang);
      }
      fprintf(f,"</h1><select id=\"stuff\" class=\"form-control\" data-show-subtext=\"true\" data-live-search=\"true\"><option disabled selected value> -- Selecione uma palavra -- </option>");
}

void printPostIndex(FILE* f){
      fprintf(f,"</select></div><div class=\"container\"><br/><div class=\"embed-responsive embed-responsive-16by9\"><iframe id=\"frame\" class=\"embed-responsive-item\" src=\"\" allowfullscreen></iframe></div></div>");
      fclose(f);
}

void printHTML() {
      FILE * indexF = fopen("index.html","w");
      printPreIndex(indexF);
      g_tree_foreach(conceitos, printConceito, (gpointer) indexF);
      printPostIndex(indexF);
}

gboolean printConceito(gpointer key, gpointer value, gpointer file) {
      {
            GHashTableIter iter;
            Conceito data = (Conceito) value;
            FILE* indexF = (FILE*) file;
            fprintf(indexF,"\n<option>%s</option>",data->termobase);
            char filepath[200] = {0}; strcat(filepath,data->termobase);strcat(filepath,".html");
            FILE* page = fopen(filepath,"w");
            fprintf(page,"<head><meta charset=\"utf-8\" name=\"viewport\" content=\"width=device-width, initial-scale=1, shrink-to-fit=no\"><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css\" integrity=\"sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm\" crossorigin=\"anonymous\"></head>");
            
            fprintf(page,"<h1>%s</h1>",data->termobase);

            g_hash_table_iter_init (&iter, data->traducoes);
            fprintf(page,"<h3>Traduções</h3>\n");
            while (g_hash_table_iter_next (&iter, &key, &value)) {
                  char * keyName =  g_hash_table_lookup(description,key);
                  if(keyName == NULL)
                        keyName = (char *) key;
                  fprintf(page,"<p>%s: %s</p>\n", keyName, (char *)((GList*)value)->data);
            }
            fprintf(page,"<h3>Ligações</h3>\n");
            for (GList* l = relacoes; l != NULL; l = l->next) {
                  Pair keys = (Pair) l->data;
                  fprintf(page,"<div class=\"row\">\n");
                  fprintf(page,"<div class=\"col-6 border-right\">\n");
                  printLigacao(page, keys->a1, g_hash_table_lookup(data->ligacoes, keys->a1));
                  g_hash_table_remove (data->ligacoes, keys->a1);
                  fprintf(page,"</div>\n");
                  fprintf(page,"<div class=\"col-6 border-left\">\n");
                  printLigacao(page, keys->a2, g_hash_table_lookup(data->ligacoes,keys->a2));
                  g_hash_table_remove (data->ligacoes, keys->a2);
                  fprintf(page,"</div>\n");
                  fprintf(page,"</div>\n");
            }
            g_hash_table_iter_init (&iter, data->ligacoes);
            while (g_hash_table_iter_next (&iter, &key, &value)) {
                  printLigacao(page, key, value);
            }
            fclose(page);
      }
      return FALSE;
}

void printLigacao(FILE* page, gpointer key, gpointer value) {
      char * keyName =  g_hash_table_lookup(description,key);
      if(keyName == NULL)
            keyName = (char *) key;
      fprintf(page,"<h4>%s</h4>\n", keyName);
      if(g_hash_table_contains(externs,key)){
            fprintf(page,"<p>%s", (char *)((GList*)value)->data);
            for (GList* l = ((GList*)value)->next; l != NULL; l = l->next) {
                  fprintf(page," %s", (char*)l->data);
            }
            fprintf(page,"</p>\n");
      }
      else {
            fprintf(page, "<ul>");
            for (GList* l = value; l != NULL; l = l->next) {
                  if(g_tree_lookup (conceitos, l->data)) {
                        fprintf(page,"<li><a href=\"%s.html\">%s</a></li>\n", (char *) l->data, (char *) l->data);
                  } else {
                        fprintf(page,"<li>%s</li>\n", (char *) l->data);
                  }
            }
            fprintf(page,"</ul>\n");
      }
}

gint strcmpG(gconstpointer a, gconstpointer b) {
      return strcmp((char*) a, (char*) b);
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
