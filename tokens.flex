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
[A-Za-z]+                           { yylval.s = strdup(yytext); return STRING; }

[\n,]                                  { return yytext[0]; }
[ \t]                               {}
.                                   { printf("%s", yytext); yyerror("Caracter inválido"); }
%%
/*
    \"((\\\\|\\")|[^\"])*\"
*/