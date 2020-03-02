%option header-file="json_uncomment.lex.h"
%option prefix="json_uncomment_"
%option noyywrap nounput noinput
%option nodefault
%option reentrant

%{

struct position {
  int line;
  int col;
};

struct json_uncomment_data {
  char compact;
  const char *filename;
  struct position position;
  int rc;
};

#define JSON_UNCOMMENT_DATA ((struct json_uncomment_data *)yyextra)

void update_tracking(const char *s, int len, struct position *position) {
  for(int i = 0; i < len; i++) {
    switch(s[i]) {
    case '\r':
    case '\n':
      if(i + 1 < len && s[i+1] == (s[i] == '\r' ? '\n' : '\r'))
        i++;
      position->line++;
      position->col = 0;
      break;
    default:
      position->col++;
    }
  }
}

#define DO_PRINT do { printf("%.*s", (int)yyleng, yytext); update_tracking(yytext, (int)yyleng, &JSON_UNCOMMENT_DATA->position); } while(0)

static void print_white_aux(int n) {
  while(n-- > 0)
    fwrite(" ", 1, 1, stdout);
}

#define print_white(n) do { if (!JSON_UNCOMMENT_DATA->compact) { print_white_aux(n); JSON_UNCOMMENT_DATA->position.col++; } } while(0)

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

"/*"             { print_white(2); BEGIN(C_COMMENT); }
<C_COMMENT>"*/"  { print_white(2); BEGIN(INITIAL); }
<C_COMMENT>\r    { if(!JSON_UNCOMMENT_DATA->compact) DO_PRINT; }
<C_COMMENT>\n    { if(!JSON_UNCOMMENT_DATA->compact) DO_PRINT; }
<C_COMMENT>.     { print_white(1); }

"//"            { print_white(2); BEGIN(CPP_COMMENT); }
<CPP_COMMENT>\r\n? { if(!JSON_UNCOMMENT_DATA->compact) DO_PRINT; BEGIN(INITIAL); }
<CPP_COMMENT>\n { if(!JSON_UNCOMMENT_DATA->compact) DO_PRINT;  BEGIN(INITIAL); }
<CPP_COMMENT>.  { print_white(1); }

{white}          { if(!JSON_UNCOMMENT_DATA->compact) DO_PRINT; }
"true"           { DO_PRINT; }
"false"          { DO_PRINT; }
"null"           { DO_PRINT; }

\"{utf_8}*\"     { DO_PRINT; }

{int}{frac}{exp} { DO_PRINT; }
{int}{frac}      { DO_PRINT; }
{int}{exp}       { DO_PRINT; }
{int}            {  DO_PRINT; }

[,:\{\}\][]      {  DO_PRINT; }

.                { fprintf(stderr, "%s%sparse error: unexpected: %c in line %i, column %i\n",
                           JSON_UNCOMMENT_DATA->filename ? JSON_UNCOMMENT_DATA->filename : "",
                           JSON_UNCOMMENT_DATA->filename ? ": " : "",
                           yytext[0],
                           JSON_UNCOMMENT_DATA->position.line + 1,
                           JSON_UNCOMMENT_DATA->position.col + 1
                           ); 
                   JSON_UNCOMMENT_DATA->rc = 1;
                 }

<<EOF>>          { return JSON_UNCOMMENT_DATA->rc; }
%%

int main(int argc, char *argv[]) {
  const char *filename = NULL;
  int compact = 0;
  if(argc > 1 && (!strcmp(argv[1], "--help") || !strcmp(argv[1], "-h")))
    fprintf(stderr, "Usage: json_uncomment [--compact or -c] [-f filename]\n  Reads stdin, writes stdout\n");
  else {
    int err = 0;
    FILE *in = stdin;
    for(int i = 1; i < argc; i++) {
      if(!strcmp(argv[i], "--compact") || !strcmp(argv[i], "-c"))
        compact = 1;
      else if(!strcmp(argv[i], "-f") && i + 1 < argc) {
        i++;
        FILE *f = fopen(argv[i], "rb");
        if(!f) {
          fprintf(stderr, "Unable to open file %s for reading\n", argv[i]);
          err = 1;
        } else {
          filename = argv[i];
          if(in != stdin)
            fclose(in);
          in = f;
        }
      }
    }

    if(err) {
      if(in != stdin)
        fclose(in);
    } else {
      yyscan_t scanner;
      json_uncomment_lex_init(&scanner);

      struct json_uncomment_data data;
      memset(&data, 0, sizeof(data));

      data.compact = compact;
      if(filename)
        data.filename = filename;
      json_uncomment_lex_init_extra(&data, &scanner);

      json_uncomment_set_in(in, scanner);
      json_uncomment_lex(scanner);
      json_uncomment_lex_destroy(scanner);
      return data.rc;
    }
  }
  return 1;
}
