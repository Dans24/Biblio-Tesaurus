%option noyywrap
%option yylineno

%%

#.*                                 {}


    /*palavras reservadas para os metadados*/
%extern                             {return EXTERN;}
%language                           {return LANGUAGE;}
%baselang                           {return BASELANG;}
%inv                                {return INV;}
\n\ *#.*                            {return '\n';}
\n\ +/[^ \n]                        {return LINEBREAK;}
 
    /*TIPOS atómicos*/

\".*?\"                             { yylval.s = strdup(yytext+1);yylval.s[yyleng-2]=0; return(STRING);}
[A-Za-z()]+                         { yylval.s = strdup(yytext); return STRING; }

[\n,]                                  { return yytext[0]; }
[ \t]                               {}
.                                   { printf("%s", yytext); yyerror("Caracter inválido"); }
%%
/*
    \"((\\\\|\\")|[^\"])*\"
*/