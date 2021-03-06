/* scanner.l */

%{
#include "y.tab.h"
#include "def.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <malloc.h>
FILE *f_asm;

char *copys();

%}

digit		[0-9]
fraction	[.]{digit}*
sign		[+|-]
integer		{digit}+
exp		[E|e]{integer}
float_num       {integer}{fraction}
exp_num  	[{integer}|{float_num}]{exp}
id		[a-zA-Z][a-zA-Z0-9_]*
blank		[ \t]+

%%
{blank}			; /* do nothing */
"//"			{
					printf("#%d comment\n\n",lineno);
					
					while (input()!='\n');
					lineno++;	
				}
"\n"			{ lineno++;			}
"("			{ printf("#%d %s\n\n", lineno, yytext);
                          return('(');                  }
")"			{ printf("#%d %s\n\n", lineno, yytext);
                          return(')');                  }
"{"			{ printf("#%d %s\n\n", lineno, yytext);
                          return('{');                  }
"}" 			{ printf("#%d %s\n\n", lineno, yytext);
                          return('}');                  }
"["			{ printf("#%d %s\n\n", lineno, yytext);
                          return('[');                  }
"]"			{ printf("#%d %s\n\n", lineno, yytext);
                          return(']');                  }
"->"			{ printf("#%d %s\n\n", lineno, yytext);
                          return(POINTSAT);                  }  
"."			{ printf("#%d %s\n\n", lineno, yytext); 
                          return('.');                  }  
"++"			{ printf("#%d operator   : %s\n\n", lineno, yytext);     
                          return(PLUSPLUS);                  } 
"--"			{ printf("#%d operator   : %s\n\n", lineno, yytext);   
                          return(MINUSMINUS);                  } 
"*"			{ printf("#%d operator   : %s\n\n", lineno, yytext);
                          return('*');                  } 
"/"			{ printf("#%d operator   : %s\n\n", lineno, yytext);  
                          return('/');                  }
"+"			{ printf("#%d operator   : %s\n\n", lineno, yytext);      
                          return('+');                  }  
"-"			{ printf("#%d operator   : %s\n\n", lineno, yytext);  
                          return('-');                  }

[<|>]=?			{ printf("#%d operator   : %s\n\n", lineno, yytext);
                          return(ARITHCOMPARE);         }
"="			{ printf("#%d operator   : %s\n\n", lineno, yytext);	
                          return('=');                  }  
","			{ printf("#%d %s\n\n", lineno, yytext);	
                          return(',');                  }  
";"			{ printf("#%d %s\n\n", lineno, yytext);	 
                          return(';');                  }  
{id} 			{
					int value;
					switch(id_or_keyword(yytext)) {
						case IDENTIFIER:
						if (!check_id_exist(yytext))
							test_install_sym(yytext, IDENTIFIER);
						printf("#%d ID: %s\n\n", lineno, yytext);
						value = IDENTIFIER;	
						yylval.ident= copys(yytext);
						break;
						default:
				        /* test_install_sym(yytext, id_or_keyword(yytext)); */
						printf("#%d keyword: %s\n\n", lineno, yytext);
						value = id_or_keyword(yytext);
						break;
					}
				    return(value);
				}
"/*"			{
					printf("#%d comment\n\n",lineno);
					dummy: while (input()!='*');
					if (input()=='/') 
						break;
					else 
						goto dummy;
				}
{integer}               {
							test_install_sym(yytext, INTEGER);
							printf("#%d NUM: %s\n\n", lineno, yytext);
							yylval.token= atoi(yytext);
							return(CONSTANT);
                        }
{float_num}             {
							test_install_sym(yytext, FLOAT);
							printf("#%d NUM: %s\n\n", lineno, yytext);
							return(CONSTANT);
                        }
"#"			{ while (input()!='\n') ;}
\"			{ while (input()!='"');}
.			{ printf("#%d %s\n\n", lineno, yytext); return *yytext;}

%%

int id_or_keyword(text)
char *text;
{
 int i;
 
 for (i=0; i<(sizeof(k_tab)/sizeof(KWORD)); i++) {
    if (!strcmp(text, k_tab[i].name))
       return k_tab[i].value;
 }
 return IDENTIFIER;
}

int check_id_exist(text)
char *text;
{
 int i;
 
 for (i=0; i<sym_tbl_index && sym_tbl[i].lexptr!=NULL; i++) {
   if (!strcmp(text, sym_tbl[i].lexptr))
      return TRUE;
 }
 return FALSE;
}

int yywrap()
{
 int i;
 printf("Total Lines: %d\n\n", lineno);
 printf("YYTEXT\t\tVALUE\n");
 printf("---------------------\n");
 for(i=0; i<sym_tbl_index; i++) {
    printf("%s\t\t", sym_tbl[i].lexptr);
    switch(sym_tbl[i].token) {
       case IDENTIFIER:
          printf("%s \n", sym_tbl[i].attrib.sval);
          break;
       case INTEGER:
          printf("%d \n", sym_tbl[i].attrib.ival);
          break;
       case FLOAT:
          printf("%f \n", sym_tbl[i].attrib.fval);
          break;
       default:
          printf("%s \n", sym_tbl[i].attrib.sval);
          break;
    }
 }
 return TRUE;
}

int test_install_sym(text, type)
char *text;
unsigned int type;
{
 sym_tbl[sym_tbl_index].lexptr=(char*)malloc(sizeof(char*)); 
 strcpy(sym_tbl[sym_tbl_index].lexptr, text);
 sym_tbl[sym_tbl_index].token=type;
 switch(type) {
    case IDENTIFIER:
       sym_tbl[sym_tbl_index].attrib.sval=(char*)malloc(sizeof(char*));     
       strcpy(sym_tbl[sym_tbl_index].attrib.sval, text);
       break;
    case INTEGER:
       sym_tbl[sym_tbl_index].attrib.ival=atoi(text);
       break;
    case FLOAT:
       sym_tbl[sym_tbl_index].attrib.fval=atof(text);
       break;
    default:
       sym_tbl[sym_tbl_index].attrib.sval=(char*)malloc(sizeof(char*));  
       strcpy(sym_tbl[sym_tbl_index].attrib.sval, text);
       break;
 }
 sym_tbl_index++;
 return TRUE;
}



void main(argc, argv)
int argc;
char **argv;
{

  int i;

  --argc; ++argv;
  lineno=1;
  if (argc>0) 
     yyin=fopen(argv[0], "r");
  else 
     yyin=stdin;
 
  if ((f_asm = fopen("andes.s", "w")) == NULL) {
      fprintf(stderr, "Cant open the file %s for write\n", "andes.s");
      exit(1);
  }
 
  init_symbol_table();
  code_gen_with_header(argv[0]);
  if (i = yyparse()) {
     fprintf(stderr,"Bad parse, return code %d\n", i);
  }
  else
     fprintf(stdout,"\nParsing Successfully\n");

  code_gen_global_vars();
  fprintf(f_asm,"\t.ident	\"GCC: (GNU) 4.9.0\"\n");
}




code_gen_with_header(filename)
char *filename;
{
	fprintf(f_asm,"\t.text\n");
// fprintf(f_asm,"        ifndef  ??version\n");
// fprintf(f_asm,"?debug  macro\n");
// fprintf(f_asm,"        endm\n");
// fprintf(f_asm,"$comm   macro   name,dist,size,count\n");
// fprintf(f_asm,"        comm    dist name:BYTE:count*size\n");
// fprintf(f_asm,"        endm\n");
// fprintf(f_asm,"        else\n");
// fprintf(f_asm,"$comm   macro   name,dist,size,count\n");
// fprintf(f_asm,"        comm    dist name[size]:BYTE:count\n");
// fprintf(f_asm,"        endm\n");
// fprintf(f_asm,"        endif\n");
// fprintf(f_asm,"        ?debug  S \"%s\"\n",filename);
// fprintf(f_asm,"        ?debug  C E9947CB82006746573742E63\n");
// fprintf(f_asm,"_TEXT   segment byte public 'CODE'\n");
// fprintf(f_asm,"_TEXT   ends\n");
// fprintf(f_asm,"DGROUP  group   _DATA,_BSS\n");
// fprintf(f_asm,"        assume  cs:_TEXT,ds:DGROUP\n");
// fprintf(f_asm,"_DATA   segment word public 'DATA'\n");
// fprintf(f_asm,"d@      label   byte\n");
// fprintf(f_asm,"d@w     label   word\n");
// fprintf(f_asm,"_DATA   ends\n");
// fprintf(f_asm,"_BSS    segment word public 'BSS'\n");
// fprintf(f_asm,"b@      label   byte\n");
// fprintf(f_asm,"b@w     label   word\n");
// fprintf(f_asm,"_BSS    ends\n");
// fprintf(f_asm,"_TEXT   segment byte public 'CODE'\n");

}



