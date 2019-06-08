%option noyywrap
%option yylineno

%%

#.*                                 {}
    /* Deteta inicio das linhas nos conceitos*/
SN                                  {
                                        return SCOPENOTE;
                                    }

    /*palavras reservadas para os metadados*/
%language                           {return LANGUAGE;}
%baselang                           {return BASELANG;}
%inv                                {return INV;}

 
    /*TIPOS atómicos*/

\".*?\"                             { yylval.s = strdup(yytext+1);yylval.s[yyleng-2]=0; return(STRING);}
[A-Za-z]+                           { yylval.s = strdup(yytext); return STRING; }

[\n,]                                  { return yytext[0]; }
[ \t]                               {}
.                                   { printf("%s", yytext); yyerror("Caracter inválido"); }
%%
/*
    \"((\\\\|\\")|[^\"])*\"
*/