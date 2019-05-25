default: tokens.flex main.yacc
	flex tokens.flex
	yacc main.yacc
	cc -o thesaurus y.tab.c -ly -lm

clean:
	rm -f y.tab.c lex.yy.c thesaurus

