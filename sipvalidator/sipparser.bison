/* This file is part of SIP-Validator.
   Copyright (C) 2003  Philippe Gérard, Mario Schulz

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

/* project: 	sipvalidator
 * file: 	sipparser.bison 
 *
 * Grammar-Description for Bison to generate parser
 *
**/

%{

#include <stdio.h>
#include <ctype.h>
#include <string.h>

/* yylval should be of type char */
 #define YYSTYPE char
 
// #define YYERROR_VERBOSE <-- don't use it, it's causing segfaults !!!
 
/* ****** state-managing-macros ****** */
 extern int yy_start;
 #ifndef BEGINB
 #define BEGINB (yy_start) = 1 + 2 *
 #endif
 
 #define SWITCHSTATE_START 	BEGINB   0 
 #define SWITCHSTATE_NORMAL 	BEGINB   1 
 #define SWITCHSTATE_COMMENT 	BEGINB   2
 #define SWITCHSTATE_QSTRING 	BEGINB   3
 #define SWITCHSTATE_UTF8CH  	BEGINB   4
 #define SWITCHSTATE_DATE	BEGINB   5
 #define SWITCHSTATE_SIPVERSION BEGINB   6
 #define SWITCHSTATE_RPHRASE	BEGINB   7
 #define SWITCHSTATE_WARNING	BEGINB   8
 #define SWITCHSTATE_SRVRVAL    BEGINB   9
 #define SWITCHSTATE_COMMENT2   BEGINB  10
 #define SWITCHSTATE_DIGURI	BEGINB  11
 #define SWITCHSTATE_DOMAIN	BEGINB  12
 
/* *** END OF state-managing-macros *** */

/* lex variable */
 extern char* yytext;
 extern YYSTYPE yylval;
 extern int yylineno;

/* End of message flag */
 char EOM=0; 
 
/* End of Buffer */
 #define EOB 0


 
/* ********** syntax-error-stuff ********** */

 #define SYNERRBUFSIZE 10240
 char synerrbuffer[SYNERRBUFSIZE];
 char *synerrbufp; // points to begin of synerrbuffer
 char *errbufp; // points to one after the last entry
 int synerrbuf_left;

 int numSynErrs=0;
 void logerrmsg(char* errmsg);
 void logsemerrmsg(char* errmsg);
 int yyerror(char *s); 
 void resetSynerrbuf();

/* ******* END OF syntax-error-stuff ****** */

/* declaration of predicate-methods */
 int isHexdig();
 int isLHexdig();
 
/* prepare parsing-method */ 
void initParsing();

%}

%glr-parser // use glr-parsing-algorithm

%start  sip_message

%token 	ALPHA DIGIT

	SIP  SIP_COLON SIPS_COLON TRANSPORTE USERE METHODE TTLE MADDRE

	SP HTAB CRLF SEMI LWS LWSSQR LPAREN_SV RPAREN_C2 COMMA_SP
	
	STAR SLASH EQUAL LPAREN RPAREN RAQUOT COMMA SEMI COLON
 	
	SDQUOTE LWS_SDQUOTE SDQUOTE_LWS SBSLASH SHCOMMA
	
	/* message-header-names */
 	 ACCEPT_HC ACCEPT_ENCODING_HC ACCEPT_LANGUAGE_HC ALERT_INFO_HC ALLOW_HC 
 	 AUTHENTICATION_INFO_HC
 	 AUTHORIZATION_HC CALL_ID_HC CALL_INFO_HC CONTACT_HC CONTENT_DISPOSITION_HC
 	 CONTENT_ENCODING_HC
 	 CONTENT_LANGUAGE_HC CONTENT_LENGTH_HC CONTENT_TYPE_HC CSEQ_HC DATE_HC 
 	 ERROR_INFO_HC EXPIRES_HC
 	 FROM_HC IN_REPLY_TO_HC MAX_FORWARDS_HC MIME_VERSION_HC MIN_EXPIRES_HC
 	 ORGANIZATION_HC
 	 PRIORITY_HC PROXY_AUTHENTICATE_HC PROXY_AUTHORIZATION_HC PROXY_REQUIRE_HC
 	 RECORD_ROUTE_HC 
 	 REPLY_TO_HC REQUIRE_HC RETRY_AFTER_HC ROUTE_HC SERVER_HC SUBJECT_HC
 	 SUPPORTED_HC TIMESTAMP_HC 
 	 TO_HC UNSUPPORTED_HC USER_AGENT_HC VIA_HC WARNING_HC WWW_AUTHENTICATE_HC
 	 HEADER_NAME_HC
 	
 	DIGEST_LWS 
	
	USERNAME_E URI_E
	
	CNONCE_E NC_E RESPONSE_E  NEXTNONCE_E RSPAUTH_E
 	PURPOSE_E HANDLING_E 
	REALM_E DOMAIN_E NONCE_E OPAQUE_E ALGORITHM_E  
	TTL_E MADDR_E RECEIVED_E BRANCH_E QOP_E
	
	DURATION_E STALE_E_TRUE STALE_E_FALSE
	
	INVALID_CHAR
	
	/* special-state tokens */
	 CTEXTH QDTEXTH QUOTED_PAIR UTF8_CONT
	 x21_7E xC0_DF xE0_EF xF0_F7 xF8_Fb xFC_FD
	 
	 /* state date */
 	  GMT
	  MON TUE WED THU FRI SAT SUN
          JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC 

%%
		
alphanum	:	ALPHA
		|	DIGIT
		;

hexdig		:	ALPHA { if (!isHexdig())logerrmsg("no hexdigit"); }
		|	DIGIT
		; /* aBNF: DIGIT / "A" / "B" / "C" / "D" / "E" / "F" */
	
reserved	:	';'
		|	'/'
		|	'?'
		|	':'
		|	'@'
		|	'&'
		|	'='
		|	'+'
                |	'$'
                |	','
                ;
                     
unreserved	:	alphanum
		|	mark	
		;
		
mark		:	'-'
		|	'_'
		|	'.'
		|	'!'
		|	'~'
		|	'*'
		|	SHCOMMA
		|	'('
		|	')'
		;

escaped		:	'%' hexdig hexdig	
		;
				
Lws		:	SP
		|	HTAB
		|	LWS
		;
		
 /* Sws unused due rule-transformations */

 /* HColon is not needed anymore cause of catching it with lexer */
 		
text_utf8_trim	:  	text_utf8char_plus text_utf8_trim_h
		;  /* aBNF: TEXT_UTF8_TRIM  =  1*TEXT_UTF8char *(1*LWS TEXT_UTF8char) 
							! changed due to ambiguity ! */
 
text_utf8_trim_h: 	/* empty */
		|	text_utf8_trim_h lws_plus text_utf8char
		;

lws_plus	:	Lws
		|	lws_plus Lws
		;
			
text_utf8char	:	x21_7E
		|	utf8_nonascii
		;
		
text_utf8char_plus:	text_utf8char
		|	text_utf8char_plus text_utf8char
		;

utf8_nonascii	:	xC0_DF UTF8_CONT
		|	xE0_EF UTF8_CONT UTF8_CONT
		|	xF0_F7 UTF8_CONT UTF8_CONT UTF8_CONT
		|	xF8_Fb UTF8_CONT UTF8_CONT UTF8_CONT UTF8_CONT
		|	xFC_FD UTF8_CONT UTF8_CONT UTF8_CONT UTF8_CONT UTF8_CONT
		;
		
lhex		:	ALPHA { if(!isLHexdig())logerrmsg("no lhexdigit(0-9,a-f)"); }
		|	DIGIT
		; /* aBNF: DIGIT / %x61-%x66 ; a-f */
	
token		:	 token_h
		|	 token token_h
		;
					
token_h 	:	alphanum
		|	'-'
		|	'.'
		|	'!'
		|	'%'
		|	'*'
		|	'_'
		|	'+'
		|	'`'
		|	SHCOMMA
		|	'~'
		;

/* rule separators unneeded  */

word		:	word_h
		|	word word_h
		;	
		
word_h		:	alphanum
		|	'-'
		|	'.'
		|	'!'
		|	'%'
		|	'*'
		|	'_'
		|	'+'
		|	'`'
		|	SHCOMMA
		|	'~'
		|	'('
		|	')'
		|	'<'
		|	'>'
		|	':'
		|	SBSLASH
		|	SDQUOTE
		|	'/'
		|	'['
		|	']'
		|	'?'
                |	'{'
                |	'}'
		;

Star    	:	'*'
		|	STAR
		;
		
Slash   	:	'/'
		|	SLASH
		;
		
Equal		:	'='
		|	EQUAL		
		;

Lparen  	:	'('
		|	LPAREN
		;
		
Rparen  	:	')'
		|	RPAREN
		;
		
Raquot		: 	'>'
		|	RAQUOT
		;		
		
Laquot		: 	'<'
		|	Lws '<'
		;

Comma   	:  	','
		|	COMMA
		;
		
Semi		:	';'
		|	SEMI
		;

Colon		:	':'
		|	COLON
		;
		
LDquot		:	SDQUOTE
		|	LWS_SDQUOTE
		;

RDquot		:	SDQUOTE
		|	SDQUOTE_LWS
		;
	
comment		:	Lparen { SWITCHSTATE_COMMENT; } comment_hh Rparen { SWITCHSTATE_NORMAL; }
		;

comment_h	:	Lparen comment_hh Rparen
		;
		
comment_hh	:	/* empty */
		|	comment_hh ctext
		|	comment_hh QUOTED_PAIR
		|	comment_hh comment_h
		;

ctext		:	CTEXTH /* %x21-27 / %x2A-5B / %x5D-7E */
		|	utf8_nonascii
		|	Lws
		;
	                  
quoted_string	:	SDQUOTE { SWITCHSTATE_QSTRING; } quoted_string_h { SWITCHSTATE_NORMAL; } 
		|	LWS_SDQUOTE { SWITCHSTATE_QSTRING; } quoted_string_h { SWITCHSTATE_NORMAL; }
		; /* aBNF: SWS DQUOTE *(qdtext / quoted-pair ) DQUOTE */

/* to solve ... [Lws] [Lws] ... ambiguity (problematic was: X Lws Y) */
quoted_string_lwssqr:	SDQUOTE { SWITCHSTATE_QSTRING; } quoted_string_h { SWITCHSTATE_NORMAL; } 
		|	LWSSQR SDQUOTE { SWITCHSTATE_QSTRING; } quoted_string_h { SWITCHSTATE_NORMAL; }
		; /* aBNF: SWS DQUOTE *(qdtext / quoted-pair ) DQUOTE */

quoted_string_h	:	quoted_string_hh SDQUOTE
		;
		
quoted_string_hh:	/* empty */
		|	quoted_string_hh qdtext
		|	quoted_string_hh QUOTED_PAIR
		;
		
qdtext		:	Lws
		|	QDTEXTH	/* %x21 / %x23-5B / %x5D-7E */
		|	utf8_nonascii
		;		

sip_uri		:	SIP_COLON { SWITCHSTATE_START; } sip_uri_h { SWITCHSTATE_NORMAL; }
		; /* aBNF: SIP-URI = "sip:" [ userinfo ] hostport uri-parameters [ headers ] */

sip_uri_h       :  	hostport uri_parameters
		|	userinfo hostport uri_parameters
		|	hostport uri_parameters headers
		|	userinfo hostport uri_parameters headers
		; 
		 
sips_uri	:	SIPS_COLON { SWITCHSTATE_START; } sips_uri_h { SWITCHSTATE_NORMAL; }
		; /* aBNF: SIP-URI = "sips:" [ userinfo ] hostport uri-parameters [ headers ] */

sips_uri_h	:  	hostport uri_parameters
		|	userinfo hostport uri_parameters
		|	hostport uri_parameters headers
		|	userinfo hostport uri_parameters headers
		; 

userinfo        :	user '@'
		|	user ':' password '@'
		/* Telephone-Subscriber rules are syntactically included in the user-rule cause
		   all characters that aren't allowed in the user-rule have to be escaped and
		   escaping is allowed in the user-rule !!! 
		|	telephone_subscriber '@'
		|	telephone_subscriber ':' password '@'			
		*/
		;
		
user		:  	user_h
		|	user user_h
		; /* aBNF: 1*( unreserved / escaped / user-unreserved ) */
		
user_h		:	unreserved
		|	escaped
		|	user_unreserved
		;

user_unreserved	:	'&'
		|	'='
		|	'+'
		|	'$'
		|	','
		|	';'
		|	'?'
		|	'/'		
		;

password	:	/* empty */
		|	password password_h
		; /* aBNF: *( unreserved / escaped / "&" / "=" / "+" / "$" / "," ) */
                    	     
password_h	:	unreserved
		|	escaped
		|	'&'
		|	'='
		|	'+'
		|	'$'
		|	','
		;
                    	     
hostport	:	host
		|	host ':' port 
		;

host		:	hostname
		|	IPv6reference
		|	IPv4address
		;

hostname       	:	hostname_h toplabel
		|	hostname_h toplabel '.'
		; /* aBNF: *( domainlabel "." ) toplabel [ "." ] */
		
hostname_h	:	/* empty */
		|	hostname_h domainlabel '.'
		;
		
domainlabel	:	alphanum
		|	alphanum label_h alphanum
		; /* aBNF: alphanum / alphanum *( alphanum / "-" ) alphanum */
		
toplabel	:	ALPHA
		|	ALPHA label_h alphanum
		; /* aBNF: ALPHA / ALPHA *( alphanum / "-" ) alphanum */

label_h		:	/* empty */	
		|	label_h alphanum
		|	label_h '-'
		;	
		
IPv4address	:	digit1_3 '.' digit1_3 '.' digit1_3 '.' digit1_3
		; /* aBNF: 1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT */
	
digit1_3	:	DIGIT
		|	DIGIT DIGIT
		|	DIGIT DIGIT DIGIT
		;
	
IPv6reference	:	'[' IPv6address ']'
		;
		
IPv6address     :	hexpart
		|	hexpart ':' IPv4address
		;
	
hexpart		:	hexseq
		|	hexseq ':' ':'
		|	hexseq ':' ':' hexseq
		|	':' ':' 
		|	':' ':' hexseq
		;
	
hexseq		:	hex4
		|	hexseq ':' hex4
		;

hex4		:	hexdig
		|	hexdig hexdig
		|	hexdig hexdig hexdig
		|	hexdig hexdig hexdig hexdig
		;
		
port 		:	number
		; /* aBNF port = 1*DIGIT */

/* telephone-subscriber obsolete -> s.a. rule userinfo */

uri_parameters	:	/* empty */
		|	uri_parameters ';' { SWITCHSTATE_NORMAL; } uri_parameter
		;
		
uri_parameter	:	transport_param 
		|	user_param 
		| 	method_param
                |	ttl_param
                |	maddr_param
                |	{ SWITCHSTATE_START; } other_param /* includes lr_param */
               	;

transport_param	:	TRANSPORTE { SWITCHSTATE_START; } token
                ; /* aBNF: "transport=" ( "udp" / "tcp" / "sctp" / "tls" / other_transport) */
                
/* other_transport=token obsolete */ 
                    
user_param	:	USERE { SWITCHSTATE_START; } token
		; /* aBNF: "user=" ( "phone" / "ip" / other-user) */
		
/* other_user = token obsolete */ 
              	
method_param	:	METHODE { SWITCHSTATE_START; } method
		;
		
ttl_param       :	TTLE { SWITCHSTATE_START; } ttl
		;
		
maddr_param     :	MADDRE { SWITCHSTATE_START; } host
		;
		
/* lr_param "lr" <-- obsolete */
		;
		
other_param	:	pname
		|	pname '=' pvalue
		; /* aBNF: other_param = pname [ "=" pvalue  ] */
		
/* rules with SIP_COLON and SIPS_COLON have been added to avoid
 * conflicts when these tokens occur in pname
**/
pname		:	paramchar
		|	SIP_COLON  { SWITCHSTATE_START; }
		| 	SIPS_COLON { SWITCHSTATE_START; }
		|	pname paramchar
		|	pname SIP_COLON { SWITCHSTATE_START; }
		|	pname SIPS_COLON { SWITCHSTATE_START; }
		;
		
pvalue		:	paramchar
		|	pvalue paramchar
		;
		
paramchar	:	param_unreserved
		|	unreserved
		|	escaped
		;
		
param_unreserved:	'[' | ']' | '/' | ':' | '&' | '+' | '$'
		;

headers         :  	'?' header headers_h
		;
		
headers_h	:	/* empty */
		|	headers_h '&' header
		;
				
header          :	hname '=' hvalue
		;
		
hname		:	hname_h
		|	hname hname_h	
		; /* aBNF: 1*( hnv-unreserved / unreserved / escaped ) */
		
hname_h		:	hnv_unreserved
		|	unreserved
		|	escaped
		;
		
hvalue		:	/* empty */
		|	hvalue hvalue_h	
		; /* aBNF: *( hnv-unreserved / unreserved / escaped ) */

hvalue_h	:	hnv_unreserved
		|	unreserved
		|	escaped
		;
			
hnv_unreserved	:	'['
		|	']'
		|	'/'
		|	'?'
		|	':'
		|	'+'
		|	'$'
		;

sip_message	:	{ initParsing(); } sip_message_h { YYACCEPT; }
		;

sip_message_h	:	request  
		|	response
		;
			
request		:	request_line message_header_star CRLF;
		;
				
request_line	:	method SP request_uri SP { SWITCHSTATE_SIPVERSION; } sip_version CRLF 
				{ SWITCHSTATE_NORMAL; }
		; /* errors caught by status-line */
					
request_uri	:	sip_uri  
		|	sips_uri
		|	absoluteUri
		;
		
absoluteUri	:	scheme ':' { SWITCHSTATE_START; } absoluteUri_h { SWITCHSTATE_NORMAL; }
		;		
		
/* added to solve problem with domain (SPACES; Lws after RDQuot -> states) */
absoluteUri_domain:	scheme ':' absoluteUri_h
		;
		
absoluteUri_h	:	hier_part
		|	opaque_part
		;

/* ! rules hier-part, authority, srvr changed to solve ambiguity-conflict ! */			
hier_part       :       ready_path
                |       ready_path '?' query
                ;

ready_path      :       '/' authority
                |       '/' '/' authority
                ;
			
abs_path	:	'/' path_segments
		;

opaque_part	:	uric_no_slash uric_star
		;
		
uric		:	reserved
		|	unreserved
		|	escaped
		;
		
uric_star	:	/* empty */
		|	uric_star uric
		; /* aBNF: *uric */
		
uric_no_slash	:	unreserved
		|	escaped
		|	';'
		|	'?'
		|	':'
		|	'@'
		|	'&'
		|	'='
		|	'+'
		|	'$'
		|	','
		;

path_segments	:	segment path_segments_h
		;

path_segments_h	:	/* empty */	
		|	path_segments_h '/' segment
		; /* aBNF: *( "/" segment ) */
		
segment		:	pchar_star segment_h
		;
		
segment_h	:	/* empty */
		|	segment_h ';' param
		;

param          	:	pchar_star
		;

pchar		:	unreserved
		|	escaped
		|	':'
		|	'@'
		|	'&'
		|	'='
		|	'+'
		|	'$'
		|	','
		;
		
pchar_star	:	/* empty */
		|	pchar_star pchar
		; /* aBNF: *pchar */

scheme		:	ALPHA
		|	ALPHA scheme_h
		;		

scheme_h	:	scheme_hh
		|	scheme_h scheme_hh
		;
	
scheme_hh	:	ALPHA
		|	DIGIT
		|	'+'
		|	'-'
		|	'.'
		;
		
/* ! rules hier-part, authority, srvr changed to solve ambiguity-conflict ! */			
authority	:	srvr
		;

srvr		:	/* empty */
		|	reg_name
		|	hilf_reg '@' '@' hostport
		;

hilf_reg        :       reg_name '/' hilf_reg1    /* wenn / dann 2 mal @ alle anderen Faelle ueber reg_name mgl. */
                ;
		
hilf_reg1       :	/* empty */
                |       '/'
                |       hilf_reg
                |       reg_name
                ;		
		
				
reg_name	:	reg_name_h 
		|	reg_name reg_name_h
		; /* aBNF: 1*( unreserved / escaped / "$" / "," / ";" 
		 		/ ":" / "@" / "&" / "=" / "+" ) */

reg_name_h	:	unreserved
		|	escaped
		|	'$'
		|	','
		|	';'
		|	':'
		|	'@'
		|	'&'
		|	'='
		|	'+'
		;
                  
query		:	uric_star
		;

sip_version	: 	SIP '/' number '.' number 
		;

message_header	:	message_header_h CRLF 
				{ SWITCHSTATE_NORMAL; }
		|	error
				{ SWITCHSTATE_NORMAL; yyclearin; yyerrok; if (EOM) YYACCEPT; }
		;

message_header_h:	Accept
                |	Accept_Encoding
                |	Accept_Language
                |	Alert_Info
                |	Allow
                |  	Authentication_Info
                |  	Authorization
                |  	Call_ID
                |  	Call_Info
                |  	Contact
                |  	Content_Disposition
                |  	Content_Encoding
                |  	Content_Language
                |  	Content_Length
                |  	Content_Type
                |  	CSeq
                |  	Date
                |  	Error_Info
                |  	Expires
                |  	From
                |  	In_Reply_To
                |  	Max_Forwards
                |  	MIME_Version
                |  	Min_Expires
                |  	Organization
                |  	Priority
                |  	Proxy_Authenticate
                |  	Proxy_Authorization
                |  	Proxy_Require
                |  	Record_Route
                |  	Reply_To
                |  	Require
                |  	Retry_After
                |  	Route
                |  	Server
                |  	Subject
                |  	Supported
                |  	Timestamp
                |  	To
                |  	Unsupported
                |  	User_Agent
                |  	Via
                |  	Warning
                |  	WWW_Authenticate
                |  	extension_header
		;
		
message_header_star:	/* empty */
		|	message_header_star message_header
		; /* aBNF: *(message_header) */
									
method		:	token /* extension_method, INVITE ... -> evtl. Semcheck */
		;

/* extension_method:	token; <-- obsolete */
										
response	:	status_line message_header_star CRLF 
			/* [message_body] -> unnecessary */
		;
				
status_line 	: 	sip_version SP status_code SP reason_phrase CRLF
		|	error { SWITCHSTATE_NORMAL; yyclearin; yyerrok; if (EOM) YYACCEPT; }
		;
						
status_code	: 	DIGIT DIGIT DIGIT /* <-- extension_code */
		;

reason_phrase	: 	{ SWITCHSTATE_RPHRASE; } reason_phrase_h { SWITCHSTATE_NORMAL; }
		;
		
		
reason_phrase_h	:	/* empty */
		|	reason_phrase_h reserved
		|	reason_phrase_h unreserved
		|	reason_phrase_h escaped
		|	reason_phrase_h utf8_nonascii
		|	reason_phrase_h UTF8_CONT
		|	reason_phrase_h SP
		|	reason_phrase_h HTAB
		;
					
Accept		: 	ACCEPT_HC
		|	ACCEPT_HC accept_range Accept_h	
		;			

Accept_h	:	/* empty */
		|	Accept_h Comma accept_range
		;
		
accept_range	:	token '/' token accept_range_h
		;

accept_range_h	:	/* empty */
		|	accept_range_h Semi generic_param
		; 

/* used by rule encoding, language */
accept_param	:	generic_param // evtl. semantikcheck "q" EQUAL qvalue
		;

/* qvalue = ( "0" [ "." 0*3DIGIT ] ) / ( "1" [ "." 0*3("0") ] ) <-- obsolete */
				
generic_param 	:  	token
		|	token Equal gen_value
		;
		
gen_value	:  	token  
		|	IPv6reference  /* hostname&IPv4address from host included in token */ 
		|	quoted_string_lwssqr
		;
 
Accept_Encoding	:	ACCEPT_ENCODING_HC
		|	ACCEPT_ENCODING_HC encoding Accept_Encoding_h
		;

Accept_Encoding_h:	/* empty */
		|	Accept_Encoding_h Comma encoding
		;
		
encoding	:	codings encoding_h
		;

encoding_h	:	/* empty */
		|	encoding_h Semi accept_param
		;

codings		:	content_coding /* '*' -> just included in token */
		; /* aBNF: codings =  content-coding / "*" */
		
content_coding	:	token
		;

Accept_Language	:	ACCEPT_LANGUAGE_HC { SWITCHSTATE_START; } Accept_Language_h { SWITCHSTATE_NORMAL; }
		;

Accept_Language_h:	/* empty */
		|	language Accept_Language_hh
		;
		
Accept_Language_hh:	/* empty */
		|	Accept_Language_hh Comma language
		;
                     
language	:	language_range language_h
		;

language_h	:	/* empty */
		|	language_h Semi accept_param
		;

language_range	:	alpha1_8 language_range_h
		|	'*' 
		;

language_range_h:	/* empty */
		|	language_range_h '-' alpha1_8
		; /* aBNF: *("-" 1*8ALPHA) */

alpha1_8	:	ALPHA
		|	ALPHA ALPHA
		|	ALPHA ALPHA ALPHA
		|	ALPHA ALPHA ALPHA ALPHA
		|	ALPHA ALPHA ALPHA ALPHA ALPHA
		|	ALPHA ALPHA ALPHA ALPHA ALPHA ALPHA
		|	ALPHA ALPHA ALPHA ALPHA ALPHA ALPHA ALPHA
		|	ALPHA ALPHA ALPHA ALPHA ALPHA ALPHA ALPHA ALPHA
		; /* aBNF: 1*8ALPHA */


Alert_Info	:	ALERT_INFO_HC alert_param Alert_Info_h
		;
		
Alert_Info_h	:	/* empty */ 
		|	Alert_Info_h Comma alert_param
		; /* aBNF: *(COMMA alert-param) */

alert_param	:	Laquot absoluteUri Raquot alert_param_h
		;

alert_param_h	:	/* empty */
		|	alert_param_h Semi generic_param
		; /* aBNF: *(SEMI generic-param) */


Allow		:	ALLOW_HC
		|	ALLOW_HC method Allow_h
		;
		
Allow_h		:	/* empty */
		|	Allow_h Comma method
		; /* aBNF: *(COMMA Method) */

Authorization	:	AUTHORIZATION_HC credentials
		;
		
credentials	:	DIGEST_LWS digest_response
		|	other_response
		;

digest_response	:	dig_resp digest_response_h 
		;

digest_response_h:	/* empty */
		|	digest_response_h Comma dig_resp	
		; /* aBNF: *(COMMA dig-resp) */

dig_resp	:	username
		|	realm
		|	nonce
		|	digest_uri	
		|	dresponse
		|	algorithm
		|	cnonce
		|	opaque
		|	message_qop
		|	nonce_count
		|	auth_param
		;

username	:	USERNAME_E username_value
		;
		
username_value	:	quoted_string
		;
		
digest_uri	:	URI_E { SWITCHSTATE_DIGURI; } LDquot digest_uri_value RDquot { SWITCHSTATE_NORMAL; }
		;
		
digest_uri_value:	rquest_uri
		;

/*  ###  Request Uri  ### */
rquest_uri     	: 	"*" 
		| 	scheme ':' pchar_star
		| 	abs_path
		;	
		
message_qop	:	QOP_E qop_value
		;

cnonce		:	CNONCE_E cnonce_value
		;
		
cnonce_value	:	nonce_value
		;
		
nonce_count	:	NC_E nc_value
		;
		
nc_value	:	lhex lhex lhex lhex lhex lhex lhex lhex
		;
		
dresponse	:	RESPONSE_E request_digest
		;
		
request_digest	:	LDquot request_digest_h RDquot
		; /* aBNF: LDQUOT 32LHEX RDQUOT */
		
request_digest_h:	request_digest_hh request_digest_hh request_digest_hh request_digest_hh
		;
		
request_digest_hh:	lhex lhex lhex lhex lhex lhex lhex lhex
		;
		
auth_param	:	auth_param_name Equal token
		|	auth_param_name Equal quoted_string_lwssqr
		;
		
comma_auth_param_star:	/* empty */
                |	comma_auth_param_star Comma auth_param
                ; /* aBNF: *(COMMA auth-param) */
      
auth_param_name	:	token
		;
		
other_response	:	auth_scheme Lws auth_param comma_auth_param_star
		;
                     
auth_scheme	:	token
		;

Authentication_Info:	AUTHENTICATION_INFO_HC ainfo Authentication_Info_h 
         	;               

Authentication_Info_h:	/* empty */
		|	Authentication_Info_h Comma ainfo
		; /* aBNF: *(COMMA ainfo) */
		
ainfo		:	nextnonce
		|	message_qop
		|	response_auth
		|	cnonce
		|	nonce_count
		;
		
nextnonce	:	NEXTNONCE_E nonce_value
		;
		
response_auth	:	RSPAUTH_E response_digest
		;
		
response_digest	:	LDquot RDquot
		|	LDquot response_digest_h RDquot
		; /* LDQUOT *LHEX  RDQUOT */

response_digest_h:	lhex
		|	response_digest_h lhex
		; /* aBNF: 1*(LHEX) */

Call_ID		:	CALL_ID_HC { SWITCHSTATE_START; } callid { SWITCHSTATE_NORMAL; }
		;

callid		:	word
		|	word '@' word
		;

Call_Info	:	CALL_INFO_HC info Call_Info_h
		;
		
Call_Info_h	:	/* empty */
		|	Call_Info_h Comma info
		; /* aBNF: *(COMMA info) */
		
info		:	Laquot absoluteUri Raquot info_h 
		;
		
info_h		:	/* empty */
		|	info_h Semi info_param
		; /* aBNF: *( SEMI info-param) */

info_param	: 	PURPOSE_E token  /* <-- "icon" | "info" | "card" | token */
		|	generic_param
		;
		
Contact		: 	CONTACT_HC Star
		|	CONTACT_HC contact_param Contact_h
		;

Contact_h	:	/* empty */
		|	Contact_h Comma contact_param
		; /* aBNF: *(COMMA contact_param) */

contact_param	:	name_addr contact_param_h 
		|	addr_spec contact_param_h
		;
		
contact_param_h	:	/* empty */
		|	contact_param_h Semi contact_params
		;	/* aBNF: *(SEMI contact-params) */

name_addr	:	display_name Laquot addr_spec Raquot
		| 	Laquot addr_spec Raquot
		;
		
addr_spec	:	sip_uri		
		|	sips_uri
		|	absoluteUri
		;

display_name	:	display_name_h
		|	quoted_string
		; /* aBNF: 1*(token LWS)/quoted-string */
		
display_name_h	:	token Lws
		|	display_name_h token Lws
		; /* aBNF: 1*(token LWS) */
		
contact_params	:	generic_param /* evtl. semanticcheck for c_p_q, c_p_expires */
		; /* aBNF: contact-params =  c-p-q/c-p-expires/contact-extension */
		
/* 
// obsolete:
c_p_q		:	'q' Equal qvalue;		
c_p_expires	:	EXPIRES_E delta_seconds;
contact_extension:	generic_param;
*/
		
delta_seconds	:	number
		; /* aBNF: 1*DIGIT */

Content_Disposition: 	CONTENT_DISPOSITION_HC disp_type Content_Disposition_h
		;

Content_Disposition_h:	/* empty */
		|	Content_Disposition_h Semi disp_param
		; /* aBNF: *( SEMI disp-param ) */

disp_type	:	token 
                	/* "render" | "session" | "icon" | "alert" | disp_extension_token */
               	;
               	 
disp_param	:	handling_param
		|	generic_param
		;

handling_param	:	HANDLING_E token 
			/* "optional" "required" other_handling */
		;
		
/* other_handling = token <-- obsolete */
		
/* disp_extension_token = token <-- obsolete */
		;
		
Content_Encoding:	CONTENT_ENCODING_HC content_coding Content_Encoding_h
		;
		
Content_Encoding_h:	/* empty */
		|	Content_Encoding_h Comma content_coding
		; /* aBNF: *(COMMA content-coding) */
		
Content_Language:	CONTENT_LANGUAGE_HC { SWITCHSTATE_START; } language_tag 
					Content_Language_h { SWITCHSTATE_NORMAL; }
		;

Content_Language_h:	/* empty */
		|	Content_Language_h Comma language_tag
		; /* aBNF: *(COMMA language-tag) */
		
language_tag	:	primary_tag language_tag_h
		;
		
language_tag_h	:	/* empty */
		|	language_tag_h '-' subtag
		; /* aBNF: *( "-" subtag ) */
		
primary_tag	:	alpha1_8
		;
		
subtag		:	alpha1_8
		;

Content_Length	:	CONTENT_LENGTH_HC number
		;

Content_Type	:	CONTENT_TYPE_HC media_type
		;
		 
media_type	:	m_type Slash m_subtype media_type_h
		;
		
media_type_h	:	/* empty */
		|	media_type_h Semi m_parameter
		; /* aBNF: *(SEMI m-parameter) */

m_type		: token /* s.b. */ 
		; /* aBNF: m-type = discrete_type / composite_type */
		
/* discrete-type  = "text" / "image" / "audio" / "video" / "application" / extension-token */
/* composite-type = "message" / "multipart" / extension-token *

/* discrete_type, composite_type obsolete -> merged */
		
extension_token	:	token /* <-- ietf_token, x_token */
		;
		
/* ietf_token = token obsolete */
		
/* x_token = 'x-' token */
		;
		
m_subtype	:	extension_token
		/* |	iana_token */
 		;
/* iana_token obsolete -> only used in m_subtype, extension_token just contains token*/
		
m_parameter	:	m_attribute Equal m_value
		;

m_attribute	:	token
		;
		
m_value		:	token
		|	quoted_string_lwssqr
		;
		
CSeq		:	CSEQ_HC number Lws method
		;
		
Date		:	DATE_HC { SWITCHSTATE_DATE; } sip_date { SWITCHSTATE_NORMAL; }
		;
		
sip_date	:	rfc1123_date
		;

rfc1123_date	:	wkday COMMA_SP date1 SP time SP GMT
		;
		
date1		:	digit2 SP month SP digit4 
		; /* day month year (e.g., 02 Jun 1982) */
		
time		:	digit2 ':' digit2 ':' digit2  /* 00:00:00 - 23:59:59 */
		;

digit2		:	DIGIT DIGIT
		;

digit4		:	DIGIT DIGIT DIGIT DIGIT
		;

wkday		:	MON
		|	TUE
		|	WED
                |	THU
                |	FRI
                |	SAT
                |	SUN
                ;
                
month		:	JAN
		|	FEB
		|	MAR
		|	APR
		|	MAY
		|	JUN
		|	JUL
		|	AUG
		|	SEP 
		|	OCT
		|	NOV
		|	DEC
		;
		
Error_Info	:	ERROR_INFO_HC error_uri Error_Info_h 
		;

Error_Info_h	:	/* empty */
		|	Error_Info_h Comma error_uri
		; /* aBNF: *(COMMA error-uri) */
		
error_uri	:	Laquot absoluteUri Raquot error_uri_h
		;
		
error_uri_h	:	/* empty */
		|	error_uri_h Semi generic_param
		; /* aBNF: *( SEMI generic-param ) */
		
Expires		:	EXPIRES_HC delta_seconds
		;                         
                         	
From		:	FROM_HC from_spec
		;

from_spec	:	name_addr from_spec_h
		|	addr_spec from_spec_h
		;
		
from_spec_h	:	/* empty */
		|	from_spec_h Semi from_param
		;
		
from_param	:	generic_param /* includes tag_param */
		;

/* tag_param	:	TAG_E token; <-- obsolete */	

In_Reply_To	:	IN_REPLY_TO_HC callid In_Reply_To_h
		;

In_Reply_To_h	:	/* empty */
		|	In_Reply_To_h Comma callid
		; /* aBNF: *(COMMA callid) */


Max_Forwards	:	MAX_FORWARDS_HC number
		;
		
MIME_Version	:	MIME_VERSION_HC number '.' number
		;

Min_Expires	:	MIN_EXPIRES_HC delta_seconds
		;

Organization	:	ORGANIZATION_HC { SWITCHSTATE_UTF8CH; } Organization_h { SWITCHSTATE_NORMAL; }
		;
		
Organization_h	:	/* empty */
		|	text_utf8_trim
		;

Priority	:	PRIORITY_HC priority_value
		;
		
priority_value	:	token  
		; /* aBNF: "emergency" / "urgent" / "normal" / "non-urgent" / other-priority */

/* other_priority = token <-- obsolete */
		
Proxy_Authenticate:	PROXY_AUTHENTICATE_HC challenge
		;

challenge	:	DIGEST_LWS digest_cln challenge_h
		|	other_challenge
		;
		
challenge_h	:	/* empty */
		|	challenge_h Comma digest_cln
		; /* aBNF: *(COMMA digest-cln) */
		
other_challenge	:	auth_scheme Lws auth_param comma_auth_param_star
		;
		
digest_cln	:	realm
		|	domain
		|	nonce
		|	opaque
		|	stale
		|	algorithm
		|	qop_options
		|	auth_param
		;
		
realm		:	REALM_E realm_value
		;
		
realm_value	:	quoted_string
		;
		
domain		:	DOMAIN_E { SWITCHSTATE_DOMAIN; } LDquot uri_domain domain_h RDquot { SWITCHSTATE_NORMAL; }
		;

domain_h	:	/* empty */
		|	domain_h domain_hh uri_domain
		; /* aBNF: *( 1*SP uri ) */
		
domain_hh	:	SP	
		|	domain_hh SP
		; /* aBNF: 1*SP */
		
/* uri->uri_domain, changed to solve problem with domain (SPACES,Lws after RDQuot->states) */
uri_domain		:	absoluteUri_domain
		|	abs_path
		;
		
nonce		:	NONCE_E nonce_value
		;
		
nonce_value	:	quoted_string
		;
		
opaque		:	OPAQUE_E quoted_string
		;
		
stale		:	STALE_E_TRUE
		|	STALE_E_FALSE
		;

algorithm	:	ALGORITHM_E token 
		; /* aBNF: "md5" | "md5_sess" | token */
		
qop_options	:	QOP_E LDquot qop_value qop_options_h RDquot
		;

qop_options_h	:	/* empty */
		|	qop_options_h ',' qop_value
		; /* aBNF: *("," qop-value) */

qop_value	:	token 
		; /* aBNF: "auth" | "auth_int" | token */
		
Proxy_Authorization:	PROXY_AUTHORIZATION_HC credentials
		;
		
Proxy_Require	:	PROXY_REQUIRE_HC option_tag comma_option_tag_star
		;

option_tag	:	token
		;

comma_option_tag_star:	/* empty */
		|	comma_option_tag_star Comma option_tag
		; /* aBNF: *(COMMA option-tag) */

Record_Route	:	RECORD_ROUTE_HC rec_route Record_Route_h
		;
		
Record_Route_h	:	/* empty */
		|	Record_Route_h Comma rec_route
		; /* aBNF: *(COMMA rec-route) */

rec_route	:	name_addr semi_rr_param_star
		;
		
rr_param	:	generic_param
		;

semi_rr_param_star:	/* empty */
		|	semi_rr_param_star Semi rr_param
		; /* aBNF: *( SEMI rr-param ) */
		
Reply_To	:	REPLY_TO_HC rplyto_spec
		;
		
rplyto_spec	:	name_addr rplyto_spec_h	
		|	addr_spec rplyto_spec_h	
		;
		
rplyto_spec_h	:	/* empty */
		|	rplyto_spec_h Semi rplyto_param
		; /* aBNF: *( SEMI rplyto-param ) */
		
rplyto_param	:	generic_param
		;
		
Require		:	REQUIRE_HC option_tag comma_option_tag_star
		;
		
Retry_After	:	RETRY_AFTER_HC delta_seconds Retry_After_h
		|	RETRY_AFTER_HC delta_seconds comment Retry_After_h
		;
		
Retry_After_h	:	/* empty */
		|	Retry_After_h Semi retry_param 
		; /* aBNF: *( SEMI retry-param ) */
		
retry_param	:	DURATION_E delta_seconds
		|	generic_param
		;
		
Route		:	ROUTE_HC route_param
		|	ROUTE_HC route_param Route_h
		;
		
Route_h		:	Comma route_param
		|	Route_h Comma route_param
		; /* aBNF: 1*(COMMA route-param) */

route_param	:	name_addr semi_rr_param_star
		;

/* to do -> what is if line ends with a comment and this comment ends with Lws ! */
/* RPAREN can contain Lws at the end */
Server		:	SERVER_HC { SWITCHSTATE_SRVRVAL; } server_val lws_server_val_star
		;

server_val	:	product
		|	comment_sv
		|	Lws comment_sv
		;
		
lws_server_val_star:	/* empty */
		|	Lws product lws_server_val_star
		|	Lws comment_sv lws_server_val_star
		|	Lws Lws comment_sv lws_server_val_star
		; /* aBNF: *(LWS server-val)*/
	
/* modified version of rule comment to prevent Lws-catching in rule Server, ? */
comment_sv	:	LPAREN_SV { SWITCHSTATE_COMMENT2; } comment_sv_hh RPAREN_C2 { SWITCHSTATE_SRVRVAL; }
		;
		
comment_sv_h	:	Lparen comment_sv_hh RPAREN_C2
		| 	Lparen comment_sv_hh RPAREN_C2 Lws
		;
		
comment_sv_hh	:	/* empty */
		|	comment_sv_hh ctext
		|	comment_sv_hh QUOTED_PAIR
		|	comment_sv_hh comment_sv_h
		;		

product		:	token
		|	token Slash product_version
		;

product_version	:	token
		;
		
Subject		:	SUBJECT_HC { SWITCHSTATE_UTF8CH; } Subject_h { SWITCHSTATE_NORMAL; }
		;

Subject_h	:	/* empty */
		|	text_utf8_trim
		;

Supported	:	SUPPORTED_HC
		|	SUPPORTED_HC option_tag comma_option_tag_star
		;
		

Timestamp	:	TIMESTAMP_HC number
		|	TIMESTAMP_HC number '.'
		|	TIMESTAMP_HC number '.' number
		|	TIMESTAMP_HC number Lws delay
		|	TIMESTAMP_HC number '.' Lws delay
		|	TIMESTAMP_HC number '.' number Lws delay
		; /* aBNF: Timestamp = "Timestamp" HCOLON 1*(DIGIT) [ "." *(DIGIT) ] [ LWS delay ] */

delay		:	/* empty */
		|	number
		|	'.'
		|	'.' number
		|	number '.'
		|	number '.' number
		; /* aBNF: delay = *(DIGIT) [ "." *(DIGIT) ] */
		

To		:	TO_HC name_addr To_h
		|	TO_HC addr_spec To_h
             	;
             	
To_h		:	/* empty */
		|	To_h Semi to_param
		; /* aBNF: *( SEMI to-param ) */
             
to_param	:	generic_param /* includes tag_param */
		;
		
Unsupported	:	UNSUPPORTED_HC option_tag comma_option_tag_star
		;
		
User_Agent	:	USER_AGENT_HC { SWITCHSTATE_SRVRVAL; } server_val lws_server_val_star
		;
		 
Via		:	VIA_HC via_parm
		|	VIA_HC via_parm Via_h
		;
		
Via_h		:	Comma via_parm
		|	Via_h Comma via_parm
		; /* aBNF: 1*(COMMA via-parm) */ 
		
via_parm	:	sent_protocol Lws sent_by
		|	sent_protocol Lws sent_by via_parm_h
		;

via_parm_h	:	Semi via_params
		|	via_parm_h Semi via_params
		; /* aBNF: 1*( SEMI via-params ) */


via_params	:	via_ttl 
		|	via_maddr
		|	via_received
		|	via_branch
		|	via_extension
		;
		
via_ttl		:	TTL_E ttl
		|	TTLE ttl
		;
		
via_maddr	:	MADDR_E host
		|	MADDRE host
		;
		
via_received	:	RECEIVED_E IPv4address
		|	RECEIVED_E IPv6address
		;
		
via_branch	:	BRANCH_E token
		;
		
via_extension	:	generic_param
		;
		
sent_protocol	:	protocol_name Slash protocol_version Slash transport
		;

protocol_name	:	token /* "SIP" included */
		;
		
protocol_version:	token
		;

transport	:	token
		; /* aBNF: "UDP" / "TCP" / "TLS" / "SCTP" / other-transport */
		
sent_by		:	host
		|	host Colon port
		;

ttl		:	DIGIT 
		|	DIGIT DIGIT 
		| 	DIGIT DIGIT DIGIT	
		; /* aBNF: ttl = 1*3DIGIT ; 0 to 255 */	
 
Warning		:	WARNING_HC warning_value Warning_h
		;
		
Warning_h	:	/* empty */
		|	Warning_h Comma warning_value
		; /* aBNF: *(COMMA warning-value) */
		
warning_value	:	{ SWITCHSTATE_WARNING; } warn_code SP warn_agent SP { SWITCHSTATE_NORMAL; } warn_text
		;
		
warn_code	:	DIGIT DIGIT DIGIT
		; /* aBNF: warn-code = 3DIGIT */
		
warn_agent	:	host ':' port | IPv6reference 
				/* rest of hostport is contained in pseudonym */
		|	pseudonym
		;
                     
warn_text	:	quoted_string
		;
		
pseudonym 	:	token
		;

WWW_Authenticate:	WWW_AUTHENTICATE_HC challenge
		;

extension_header:	HEADER_NAME_HC { SWITCHSTATE_UTF8CH; } header_value { SWITCHSTATE_NORMAL; }
		;
		
/* header_name	:	token; <-- obsolete */
		
header_value	:	/* empty */
		|	header_value text_utf8char 
		|	header_value UTF8_CONT
		|	header_value Lws
		; /* aBNF: *(TEXT-UTF8char / UTF8-CONT / LWS) */
		
/* message_body -> obsolete */

number		:	DIGIT
		|	number DIGIT
		;
		
%%

/* ***************************** errorhandling-procedures ******************** */

/* Handles syntaxerrors 
 *
 * Logs position of syntaxerror and bad token into a buffer
 * Resynchs parsing-position to next line.
 * Checks if EOM
 *
 * @param s	message generated by bison, ignored
 *
 * @return 0	(always)
 *
 * @changes EOM	set to one if end of message
 * @changes synerrbuffer-stuff
 * @changes numSynErrs	increase by 1
**/
int yyerror (char *s) {
	int token,len;
	char* errtoktext;
	
	/* write error-message into buffer */
	  if (synerrbuf_left-100<1) {
		fprintf(stderr,"internal syntax-error-buffer is full\n");
	  } else {
	  	errtoktext=yytext;
	  	
	  	// translate some chars into a more readable form
	  	  switch (*yytext) {
	  	  case '\t': errtoktext="TAB";
	  		     break;
		  case '\r': if (*(yytext+1)=='\n') errtoktext="CRLF";
		     	     else errtoktext="CR";
			     break;
		  case '\n': errtoktext="LF";
		  case ' ' : errtoktext="SPACE";
			     break;	 
	  	  };
	  	  
		len=snprintf(errbufp,100,"Syntaxerror at (or before) %d.%d-%d.%d [%s]\n",
			yylloc.first_line,yylloc.first_column,yylloc.last_line,
			yylloc.last_column,errtoktext);
		errbufp+=len;
		synerrbuf_left-=len;
	  };
	
	/* resynch to next CRLF or EOB */
	  do {
		token=yylex();
	  } while (token!=CRLF && token!=EOB); 	

	/* increase errornumber */
	  numSynErrs++;

	if (token==EOB) EOM=1; // bei End of Block parsen beenden
	return 0;
};

/* Handles syntaxerrors found by predicate-procedures
 *
 * Logs position of syntaxerror,bad token,description into a buffer
 *
 * @param errmsg	little description of error
 *
 * @changes synerrbuffer-stuff
 * @changes numSynErrs	increase by 1
**/
void logerrmsg(char* errmsg) {
	int len;
	/* write error-message into buffer */
	  if (synerrbuf_left-100<1) {
		fprintf(stderr,"internal syntax-error-buffer is full\n");
	  } else {
		len=snprintf(errbufp,100,"Syntaxerror at %d.%d-%d.%d [%s]: %s\n",
			yylloc.first_line,yylloc.first_column,yylloc.last_line,
			yylloc.last_column,yytext,errmsg);
		errbufp+=len;
		synerrbuf_left-=len;
		
		/* increase errornumber */
	  	  numSynErrs++;
	  };
};

/* Resets syntaxerror-stuff to init state */
void resetSynerrbuf() {
	numSynErrs=0;
 	synerrbuf_left=SYNERRBUFSIZE;
 	errbufp=synerrbuffer;
 	synerrbufp=synerrbuffer;
 	synerrbuffer[0]=0;
};

/* *************************** END OF errorhandling-procedures ************* */

/* *************************** predicate-procedures ************************ */

/* Looks whether the actual token is an HEXDIG or not
 * The actual token has to be parsed as ALPHA
 *
 * HEXDIG: a-f,A-F,0-9
 *
 * @return 0	no hexdig
 * @return 1	is hexdig
**/ 
int isHexdig() {
	int ishexdig=0;
	if (yytext[0]>=97 && yytext[0]<=102) ishexdig=1;
	if (yytext[0]>=65 && yytext[0]<=70) ishexdig=1;
	return ishexdig;
};

/* Looks whether the actual token is an LHEX or not
 * The actual token has to be parsed as ALPHA
 *
 * LHEX: a-f,0-9
 *
 * @return 0	no lhexdig
 * @return 1	is lhexdig
**/ 
int isLHexdig() {
	if (yytext[0]>=97 && yytext[0]<=102) return 1;
	return 0;
};

/* *********************** END OF predicate-procedures ********************* */


/* reset all nessescary values to initial state */
void initParsing() {
	yylineno=1;
        yylloc.first_line = yylloc.last_line = 1;
        yylloc.first_column = yylloc.last_column = 1;
	SWITCHSTATE_NORMAL; 
	EOM=0; 
	resetSynerrbuf();
};


/* include lexer-code generated with flex */
#include "sipscanner.c"

