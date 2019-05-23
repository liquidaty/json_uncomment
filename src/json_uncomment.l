%option header-file="json_uncomment.lex.h"
%option prefix="json_uncomment_"
%option noyywrap nounput noinput

%{

char minify;

#define DO_PRINT printf("%.*s", (int)yyleng, yytext)

static void print_white(int n) {
  while(!minify && n--)
    fwrite(" ", 1, 1, stdout);
}

%}

%x C_COMMENT
%x CPP_COMMENT

white   [ \t\n\r\v\f]
bom     \xEF\xBB\xBF

u2a     [\xC2-\xDF][\x80-\xBF]
u2b     \xE0[\xA0-\xBF][\x80-\xBF]
u3a     [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}
u3b     \xED[\x80-\x9F][\x80-\xBF]
u4a     \xF0[\x90-\xBF][\x80-\xBF]{2}
u4b     [\xF1-\xF3][\x80-\xBF]{3}
u4c     \xF4[\x80-\x8F][\x80-\xBF]{2}
hex     [0-9a-fA-F][0-9a-fA-F]
ustr    {white}|[\x20-\x21]|[\x23-\x5b]|[\x5d-\x7e]|\\\"|\\\\|\\\/|\\b|\\f|\\n|\\r|\\t|\\u{hex}{hex}{hex}{hex}

utf_8   {ustr}|{u2a}|{u2b}|{u3a}|{u3b}|{u4a}|{u4b}|{u4c}

int     [-]?[1-9][0-9]+|[-]?[0-9]
frac    \.[0-9]+
exp     [eE][+-]?[0-9]+

%%

"/*"            { print_white(2); BEGIN(C_COMMENT); }
<C_COMMENT>"*/" { print_white(2); }
<C_COMMENT>.    { print_white(1); }

"//"            { print_white(2); BEGIN(CPP_COMMENT); }
<CPP_COMMENT>\r\n? { if(!minify) DO_PRINT; BEGIN(INITIAL); }
<CPP_COMMENT>\n { if(!minify) DO_PRINT; BEGIN(INITIAL); }
<CPP_COMMENT>.  { print_white(1); }

{white}          { if(!minify) DO_PRINT; }
"true"           { DO_PRINT; }
"false"          { DO_PRINT; }
"null"           { DO_PRINT; }

\"{utf_8}*\"     { DO_PRINT; }

{int}{frac}{exp} { DO_PRINT; }
{int}{frac}      { DO_PRINT; }
{int}{exp}       { DO_PRINT; }
{int}            {  DO_PRINT; }



[,:\{\}\][]      {  DO_PRINT; }

.                { fprintf(stderr, "not handled: %c\n", yytext[0]); }

<<EOF>>          { return 0; }
%%

int main(int argc, char *argv[]) {
  minify = 0;
  if(argc > 1 && (!strcmp(argv[1], "--help") || !strcmp(argv[1], "-h")))
    fprintf(stderr, "Usage: json_uncomment [--minify or -m]\n  Reads stdin, writes stdout\n");
  else if(argc > 1 && (!strcmp(argv[1], "--minify") || !strcmp(argv[1], "-m")))
    minify = 1;

  json_uncomment_lex();
}
