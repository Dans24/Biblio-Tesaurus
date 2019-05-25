%code{
 #define _GNU_SOURCE
 #include <stdio.h>
 int yyerror(char *s){ fprintf(stderr,"Erro: %s\n",s);}
 int yylex();
}
%token  TERMO METADADO DIRETIVA;
%union{ 
        char* s;
      }

%type <s> TERMO METADADO DIRETIVA
%%
thesaurus   : diretivas
            |
            ;

diretivas   : diretiva
            | diretiva '\n' diretivas
            ;

diretiva    : DIRETIVA ' ' metadados
            ;

metadados   : METADADO ' ' metadados
            | METADADO
            ;
%%
 #include "lex.yy.c"
int main(){
   yyparse();
   return 0;
}
