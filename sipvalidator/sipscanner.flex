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
 * file: 	sipscanner.flex
 *
 * Descriptionfile for flex to generate the lexical analyser
 *
**/

%{
#include <stdio.h>

 int i;
 int lwsnl; // flag -> if true Lws contained '\n' - used in updlocLws...()

/* ********************************************************************	*/  
/* 		update location-information for bison - methods		*/

 void newline() {
    yylloc.first_line   = yylloc.last_line=yylineno;
    yylloc.first_column = yylloc.last_column=1;
 };

 void updloc() {
	yylloc.first_line = yylloc.last_line;
       	yylloc.first_column = yylloc.last_column;
        yylloc.last_column+=yyleng;
 };

 void updlocLwsSqr() {
 	lwsnl=0;
 	for (i=0;i<yyleng;i++) {
		if (yytext[i]=='\n') { 
			lwsnl=1;
			yylloc.first_line = yylloc.last_line;
			yylloc.last_line  = yylineno;
    			yylloc.first_column = yylloc.last_column;
			yylloc.last_column=yyleng-i;
		};
	};
	if (!lwsnl) updloc();
 };

 void updlocLws() {
 	lwsnl=0;
 	for (i=0;i<yyleng;i++) {
		if (yytext[i]=='\n') { 
			lwsnl=1;
			yylloc.first_line = yylloc.last_line;
			yylloc.last_line  = yylineno;
    			yylloc.first_column = yylloc.last_column;
			yylloc.last_column=yyleng-i;
			break;
		};
	};
	if (!lwsnl) updloc(); 
 };
 
/* ********************************************************************	*/

%}

 /* helping-rules */

WSP 		([\t]|" ")
LWS 		({WSP}*\r\n)?{WSP}+
SWS 		({LWS})?

HCOLON		(" "|[\t])*:{SWS}
HC		(" "|[\t])*:{SWS}

DIGIT 		[0-9]
ALPHA 		[A-Za-z]

TOKEN		([0-9A-Za-z\-\.\!\%\*\_\+\`\'\~])+

 /* used for caseinsensitivity of keywords */
A	[aA]
B	[bB]
C	[cC]
D	[dD]
E	[eE]
F	[fF]
G	[gG]
H	[hH]
I	[iI]
J	[jJ]
K	[kK]
L	[lL]
M	[mM]
N	[nN]
O	[oO]
P	[pP]
Q	[qQ]
R	[rR]
S	[sS]
T	[tT]
U	[uU]
V	[vV]
W	[wW]
X	[xX]
Y	[yY]
Z	[zZ]

/* END of helping-rules */
 
 /* flex should track linenumber */
%option yylineno

 /* start-states - !!! don't change order !!! */
%START nrml comment qstring utf8ch date sipversion rphrase warning srvrval comment2 diguri domain cl

%%

 /* *************************** special states ***************************** */
 /* - must come first to avoid conflicts with ALPHA,DIGIT,etc.		     */
 
<cl>{DIGIT}+		{ updloc(); yylval=atoi(yytext); return NUMBER; };

<srvrval>\({LWS}?	{ updlocLws(); return LPAREN_SV; }
<comment2>{LWS}?\)	{ updlocLws(); return RPAREN_C2; }
    
<comment,comment2>[\41-\47]|[\52-\133]|[\135-\176]  { updloc(); return CTEXTH; }

<qstring>\41|[\43-\133]|[\135-\176] 	   { updloc(); return QDTEXTH; }

 /* quoted-pair */
<comment,comment2,qstring>\\[\0-\11\13-\14\16-\177] { updloc(); return QUOTED_PAIR; }

 /* utf8 */
<comment,comment2,qstring,utf8ch,rphrase>[\300-\337]	{ updloc(); return xC0_DF; }
<comment,comment2,qstring,utf8ch,rphrase>[\340-\357]    { updloc(); return xE0_EF; }
<comment,comment2,qstring,utf8ch,rphrase>[\360-\367]    { updloc(); return xF0_F7; }
<comment,comment2,qstring,utf8ch,rphrase>[\370-\373]    { updloc(); return xF8_Fb; }
<comment,comment2,qstring,utf8ch,rphrase>[\374-\375]    { updloc(); return xFC_FD; }
<comment,comment2,qstring,utf8ch,rphrase>[\200-\277]   	{ updloc(); return UTF8_CONT; }

<utf8ch>[\41-\176] { updloc(); return x21_7E; }
 
 /* date */
<date>{G}{M}{T}	{ updloc(); return GMT; }
<date>{M}{O}{N} { updloc(); return MON; }
<date>{T}{U}{E} { updloc(); return TUE; }
<date>{W}{E}{D} { updloc(); return WED; }
<date>{T}{H}{U} { updloc(); return THU; }
<date>{F}{R}{I} { updloc(); return FRI; }
<date>{S}{A}{T} { updloc(); return SAT; }
<date>{S}{U}{N} { updloc(); return SUN; }
<date>{J}{A}{N} { updloc(); return JAN; }
<date>{F}{E}{B} { updloc(); return FEB; }
<date>{M}{A}{R} { updloc(); return MAR; }
<date>{A}{P}{R} { updloc(); return APR; }
<date>{M}{A}{Y} { updloc(); return MAY; }
<date>{J}{U}{N} { updloc(); return JUN; }
<date>{J}{U}{L} { updloc(); return JUL; }
<date>{A}{U}{G} { updloc(); return AUG; }
<date>{S}{E}{P} { updloc(); return SEP; }
<date>{O}{C}{T}	{ updloc(); return OCT; }
<date>{N}{O}{V}	{ updloc(); return NOV; }
<date>{D}{E}{C}	{ updloc(); return DEC; }
<date>", "     { updloc(); return COMMA_SP; } 
 
 /* ************************* end of special states *********************** */

<nrml>{S}{I}{P}: 		{ updloc(); return SIP_COLON; }
<nrml>{S}{I}{P}{S}:		{ updloc(); return SIPS_COLON; }
<nrml>{U}{S}{E}{R}=		{ updloc(); return USERE; }
<nrml>{M}{E}{T}{H}{O}{D}=	{ updloc(); return METHODE; }
<nrml>{T}{T}{L}=		{ updloc(); return TTLE; }
<nrml>{M}{A}{D}{D}{R}=		{ updloc(); return MADDRE; } 
<nrml>{T}{R}{A}{N}{S}{P}{O}{R}{T}= { updloc(); return TRANSPORTE; }

<nrml>^{S}{I}{P}  		{ updloc(); return SIP; }
<sipversion>{S}{I}{P} 		{ updloc(); return SIP; }

 /* message-header-names */
^{A}{C}{C}{E}{P}{T}{HC}				{ updlocLws(); return ACCEPT_HC; }
^{A}{C}{C}{E}{P}{T}-{E}{N}{C}{O}{D}{I}{N}{G}{HC} { updlocLws(); return ACCEPT_ENCODING_HC; }
^{A}{C}{C}{E}{P}{T}-{L}{A}{N}{G}{U}{A}{G}{E}{HC} { updlocLws(); return ACCEPT_LANGUAGE_HC; }
^{A}{L}{E}{R}{T}-{I}{N}{F}{O}{HC}	 	{ updlocLws(); return ALERT_INFO_HC; }
^{A}{L}{L}{O}{W}{HC}  		 		{ updlocLws(); return ALLOW_HC; }
^{A}{U}{T}{H}{E}{N}{T}{I}{C}{A}{T}{I}{O}{N}-{I}{N}{F}{O}{HC} { updlocLws(); return AUTHENTICATION_INFO_HC; }
^{A}{U}{T}{H}{O}{R}{I}{Z}{A}{T}{I}{O}{N}{HC}	{ updlocLws(); return AUTHORIZATION_HC; }
^{C}{A}{L}{L}-{I}{D}{HC}		 	{ updlocLws(); return CALL_ID_HC; }
^{I}{HC}  			 		{ updlocLws(); return CALL_ID_HC; }
^{C}{A}{L}{L}-{I}{N}{F}{O}{HC}	 		{ updlocLws(); return CALL_INFO_HC; }
^{C}{O}{N}{T}{A}{C}{T}{HC}	 		{ updlocLws(); return CONTACT_HC; }
^{M}{HC}		 			{ updlocLws(); return CONTACT_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{D}{I}{S}{P}{O}{S}{I}{T}{I}{O}{N}{HC} { updlocLws(); return CONTENT_DISPOSITION_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{E}{N}{C}{O}{D}{I}{N}{G}{HC} { updlocLws(); return CONTENT_ENCODING_HC; }
^{E}{HC}  			 		{ updlocLws(); return CONTENT_ENCODING_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{L}{A}{N}{G}{U}{A}{G}{E}{HC} { updlocLws(); return CONTENT_LANGUAGE_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{L}{E}{N}{G}{T}{H}{HC} 	{ updlocLws(); return CONTENT_LENGTH_HC; }
^{L}{HC}  			 		{ updlocLws(); return CONTENT_LENGTH_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{T}{Y}{P}{E}{HC} 	{ updlocLws(); return CONTENT_TYPE_HC; }
^{C}{HC}			 		{ updlocLws(); return CONTENT_TYPE_HC; }
^{C}{S}{E}{Q}{HC}			 	{ updlocLws(); return CSEQ_HC; }
^{D}{A}{T}{E}{HC}			 	{ updlocLws(); return DATE_HC; }
^{E}{R}{R}{O}{R}-{I}{N}{F}{O}{HC}	 	{ updlocLws(); return ERROR_INFO_HC; }
^{E}{X}{P}{I}{R}{E}{S}{HC} 		 	{ updlocLws(); return EXPIRES_HC; }
^{F}{R}{O}{M}{HCOLON}	 	 		{ updlocLws(); return FROM_HC; }
^{F}{HC}		 			{ updlocLws(); return FROM_HC; }
^{I}{N}-{R}{E}{P}{L}{Y}-{T}{O}{HC}  		{ updlocLws(); return IN_REPLY_TO_HC; }
^{M}{A}{X}-{F}{O}{R}{W}{A}{R}{D}{S}{HC}	  	{ updlocLws(); return MAX_FORWARDS_HC; }
^{M}{I}{M}{E}-{V}{E}{R}{S}{I}{O}{N}{HC}  	{ updlocLws(); return MIME_VERSION_HC; }
^{M}{I}{N}-{E}{X}{P}{I}{R}{E}{S}{HC} 		{ updlocLws(); return MIN_EXPIRES_HC; }
^{O}{R}{G}{A}{N}{I}{Z}{A}{T}{I}{O}{N}{HC}	{ updlocLws(); return ORGANIZATION_HC; }
^{P}{R}{I}{O}{R}{I}{T}{Y}{HC}  		 	{ updlocLws(); return PRIORITY_HC; }
^{P}{R}{O}{X}{Y}-{A}{U}{T}{H}{E}{N}{T}{I}{C}{A}{T}{E}{HC} { updlocLws(); return PROXY_AUTHENTICATE_HC; }
^{P}{R}{O}{X}{Y}-{A}{U}{T}{H}{O}{R}{I}{Z}{A}{T}{I}{O}{N}{HC} { updlocLws(); return PROXY_AUTHORIZATION_HC; }
^{P}{R}{O}{X}{Y}-{R}{E}{Q}{U}{I}{R}{E}{HC}	{ updlocLws(); return PROXY_REQUIRE_HC; }
^{R}{E}{C}{O}{R}{D}-{R}{O}{U}{T}{E}{HC} 	{ updlocLws(); return RECORD_ROUTE_HC; }
^{R}{E}{P}{L}{Y}-{T}{O}{HC}	 		{ updlocLws(); return REPLY_TO_HC; }
^{R}{E}{Q}{U}{I}{R}{E}{HC}  		 	{ updlocLws(); return REQUIRE_HC; }
^{R}{E}{T}{R}{Y}-{A}{F}{T}{E}{R}{HC}  		{ updlocLws(); return RETRY_AFTER_HC; }
^{R}{O}{U}{T}{E}{HC} 		 		{ updlocLws(); return ROUTE_HC; }
^{S}{E}{R}{V}{E}{R}{HC}		 		{ updlocLws(); return SERVER_HC; }
^{S}{U}{B}{J}{E}{C}{T}{HC} 		 	{ updlocLws(); return SUBJECT_HC; }
^{S}{HC}  			 		{ updlocLws(); return SUBJECT_HC; }
^{S}{U}{P}{P}{O}{R}{T}{E}{D}{HC}  		{ updlocLws(); return SUPPORTED_HC; }
^{K}{HC}  			 		{ updlocLws(); return SUPPORTED_HC; }
^{T}{I}{M}{E}{S}{T}{A}{M}{P}{HC}  		{ updlocLws(); return TIMESTAMP_HC; }
^{T}{O}{HC}  		 			{ updlocLws(); return TO_HC; }
^{T}{HC}  		 			{ updlocLws(); return TO_HC; }
^{U}{N}{S}{U}{P}{P}{O}{R}{T}{E}{D}{HC}  	{ updlocLws(); return UNSUPPORTED_HC; }
^{U}{S}{E}{R}-{A}{G}{E}{N}{T}{HC}	 	{ updlocLws(); return USER_AGENT_HC; }
^{V}{I}{A}{HC}  			 	{ updlocLws(); return VIA_HC; }
^{V}{HC}  			 		{ updlocLws(); return VIA_HC; }
^{W}{A}{R}{N}{I}{N}{G}{HC}  		 	{ updlocLws(); return WARNING_HC; }
^{W}{W}{W}-{A}{U}{T}{H}{E}{N}{T}{I}{C}{A}{T}{E}{HC} { updlocLws(); return WWW_AUTHENTICATE_HC; }
^{TOKEN}{HC}					{ updlocLws(); return HEADER_NAME_HC; }


<nrml>{D}{I}{G}{E}{S}{T}{LWS}  	    		{ updlocLws(); return DIGEST_LWS; }

<nrml>{D}{U}{R}{A}{T}{I}{O}{N}{SWS}={SWS}   	{ updlocLwsSqr(); return DURATION_E; }
<nrml>{U}{S}{E}{R}{N}{A}{M}{E}{SWS}={SWS}   	{ updlocLwsSqr(); return USERNAME_E; }
<nrml>{U}{R}{I}{SWS}={SWS}	    		{ updlocLwsSqr(); return URI_E; }
<nrml>{H}{A}{N}{D}{L}{I}{N}{G}{SWS}={SWS}   	{ updlocLwsSqr(); return HANDLING_E; } 
<nrml>{P}{U}{R}{P}{O}{S}{E}{SWS}={SWS}    	{ updlocLwsSqr(); return PURPOSE_E; }
<nrml>{N}{E}{X}{T}{N}{O}{N}{C}{E}{SWS}={SWS}  	{ updlocLwsSqr(); return NEXTNONCE_E; }
<nrml>{R}{S}{P}{A}{U}{T}{H}{SWS}={SWS}    	{ updlocLwsSqr(); return RSPAUTH_E; }
<nrml>{R}{E}{S}{P}{O}{N}{S}{E}{SWS}={SWS}   	{ updlocLwsSqr(); return RESPONSE_E; }
<nrml>{C}{N}{O}{N}{C}{E}{SWS}={SWS}	    	{ updlocLwsSqr(); return CNONCE_E; }
<nrml>{N}{C}{SWS}={SWS}	    			{ updlocLwsSqr(); return NC_E; }
<nrml>{Q}{O}{P}{SWS}={SWS} 	    		{ updlocLwsSqr(); return QOP_E; }
<nrml>{R}{E}{A}{L}{M}{SWS}={SWS} 	    	{ updlocLwsSqr(); return REALM_E; }
<nrml>{D}{O}{M}{A}{I}{N}{SWS}={SWS}     	{ updlocLwsSqr(); return DOMAIN_E; }
<nrml>{N}{O}{N}{C}{E}{SWS}={SWS} 	    	{ updlocLwsSqr(); return NONCE_E; }
<nrml>{O}{P}{A}{Q}{U}{E}{SWS}={SWS}     	{ updlocLwsSqr(); return OPAQUE_E; }
<nrml>{S}{T}{A}{L}{E}{SWS}={SWS}{F}{A}{L}{S}{E} { updlocLwsSqr(); return STALE_E_TRUE; }
<nrml>{S}{T}{A}{L}{E}{SWS}={SWS}{T}{R}{U}{E}  	{ updlocLwsSqr(); return STALE_E_FALSE; }

<nrml>{A}{L}{G}{O}{R}{I}{T}{H}{M}{SWS}={SWS}  	{ updlocLwsSqr(); return ALGORITHM_E; }
<nrml>{T}{T}{L}{SWS}={SWS} 	    		{ updlocLwsSqr(); return TTL_E; }
<nrml>{M}{A}{D}{D}{R}{SWS}={SWS}      		{ updlocLwsSqr(); return MADDR_E; }
<nrml>{R}{E}{C}{E}{I}{V}{E}{D}{SWS}={SWS}  	{ updlocLwsSqr(); return RECEIVED_E; }
<nrml>{B}{R}{A}{N}{C}{H}{SWS}={SWS}	    	{ updlocLwsSqr(); return BRANCH_E; }


 /* literals */
"/"  		{ updloc(); return '/'; }
"."  		{ updloc(); return '.'; }
"*"  		{ updloc(); return '*'; }
"="  		{ updloc(); return '='; }
"-"  		{ updloc(); return '-'; }
"!"  		{ updloc(); return '!'; }
"%"  		{ updloc(); return '%'; }
"_"  		{ updloc(); return '_'; }
"+"  		{ updloc(); return '+'; }
"`"  		{ updloc(); return '`'; }
"~"  		{ updloc(); return '~'; }	
"<"  		{ updloc(); return '<'; }
">"  		{ updloc(); return '>'; }
";"  		{ updloc(); return ';'; }
"["  		{ updloc(); return '['; }
"]"  		{ updloc(); return ']'; }
":"  		{ updloc(); return ':'; }
"@"		{ updloc(); return '@'; }
"&"		{ updloc(); return '&'; }
"$"		{ updloc(); return '$'; }
","		{ updloc(); return ','; }
"?"		{ updloc(); return '?'; }
"{"		{ updloc(); return '{'; }
"}"		{ updloc(); return '}'; }
"("		{ updloc(); return '('; }
")"		{ updloc(); return ')'; }


 /* special literals, etc. */
"'"  		{ updloc(); return SHCOMMA; } 
\\   		{ updloc(); return SBSLASH; }
\"   		{ updloc(); return SDQUOTE; }
" "  		{ updloc(); return SP; } 
[\t] 		{ updloc(); return HTAB; }
<nrml,srvrval>{LWS}	{ updlocLws(); return LWS; }


 /* for fixing lws-ambiguity-problem */
<nrml>{LWS}{LWS}		{ updlocLwsSqr(); return LWSSQR; }
<nrml>\>{LWS}			{ updlocLws(); return RAQUOT; };
<nrml,srvrval>{LWS}?\/{LWS}? 	{ updlocLwsSqr(); return SLASH; }
<nrml>{LWS}?\={LWS}? 		{ updlocLwsSqr(); return EQUAL; }
<nrml,comment>{LWS}?\({LWS}? 	{ updlocLwsSqr(); return LPAREN; }
<nrml,comment>{LWS}?\){LWS}? 	{ updlocLwsSqr(); return RPAREN; }
{LWS}?\,{LWS}? 			{ updlocLwsSqr(); return COMMA; }
{LWS}?\;{LWS}? 			{ updlocLwsSqr(); return SEMI; }
<nrml>{LWS}?\:{LWS}? 		{ updlocLwsSqr(); return COLON; }

<nrml,diguri,domain>{LWS}\"	{ updlocLws(); return LWS_SDQUOTE; }
<nrml,diguri,domain>\"{LWS}	{ updlocLws(); return SDQUOTE_LWS; }

{ALPHA} { updloc(); return ALPHA; };
{DIGIT} { updloc(); return DIGIT; };

\r 	{ return CR; }
\n {
  // location-update
    newline();
  return LF;
}

 /* rule to catch chars that aren't catched by any other rule above */
[\0-\377]	{ updloc(); return INVALID_CHAR; }

%%

#ifndef yywrap
int yywrap() {
  return 1;
}
#endif

