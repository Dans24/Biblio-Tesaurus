%option noyywrap
%option yylineno

%%
[a-z]+                                          { yylval.s = strdup(yytext); return TERMO; }
[A-Z]+                                          { yylval.s = strdup(yytext); return METADADO; }
%((language)|(baselang)|inv)                    { yylval.s = strdup(yytext + 1); return DIRETIVA; }
[ \n]                                           { return yytext[0]; }
(#[^\n])|\t                                     {}
.                                               { printf("%s", yytext); yyerror("Caracter inválido"); }
%%
/*
    \"((\\\\|\\")|[^\"])*\"
*/