/* This file is part of SIP-Validator.
   Copyright (C) 2003  Philippe Gèrard, Mario Schulz

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

/* update location-information for bison */
void updloc() {
	yylloc.first_line = yylloc.last_line;
       	yylloc.first_column = yylloc.last_column;
        yylloc.last_column+=yyleng;
};

%}

 /* helping-rules */

WSP 			([\t]|" ")
LWS 			({WSP}*[\n])?{WSP}+
SWS 			({LWS})?

HCOLON			(" "|[\t])*:{SWS}
HC			(" "|[\t])*:{SWS}

DIGIT 			[0-9]
ALPHA 			[A-Za-z]

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
%START nrml comment qstring utf8ch date sipversion rphrase

%%

 /* *************************** special states ***************************** */
 /* - must come first to avoid conflicts with ALPHA,DIGIT,etc.		     */
   
<comment>[\41-\47]|[\52-\133]|[\135-\176]  { updloc(); return CTEXTH; } 

<qstring>\41|[\43-\133]|[\135-\176] 	   { updloc(); return QDTEXTH; }

 /* quoted-pair */
<comment,qstring>\\[\0-\11\13-\14\16-\177] { updloc(); return QUOTED_PAIR; }

 /* utf8 */
<comment,qstring,utf8ch,rphrase>[\300-\337]	{ updloc(); return xC0_DF; }
<comment,qstring,utf8ch,rphrase>[\340-\357]     { updloc(); return xE0_EF; }
<comment,qstring,utf8ch,rphrase>[\360-\367]     { updloc(); return xF0_F7; }
<comment,qstring,utf8ch,rphrase>[\370-\373]     { updloc(); return xF8_Fb; }
<comment,qstring,utf8ch,rphrase>[\374-\375]     { updloc(); return xFC_FD; }
<comment,qstring,utf8ch,rphrase>[\200-\277]   	{ updloc(); return UTF8_CONT; }

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
^{A}{C}{C}{E}{P}{T}{HC}				{ updloc(); return ACCEPT_HC; }
^{A}{C}{C}{E}{P}{T}-{E}{N}{C}{O}{D}{I}{N}{G}{HC} { updloc(); return ACCEPT_ENCODING_HC; }
^{A}{C}{C}{E}{P}{T}-{L}{A}{N}{G}{U}{A}{G}{E}{HC} { updloc(); return ACCEPT_LANGUAGE_HC; }
^{A}{L}{E}{R}{T}-{I}{N}{F}{O}{HC}	 	{ updloc(); return ALERT_INFO_HC; }
^{A}{L}{L}{O}{W}{HC}  		 		{ updloc(); return ALLOW_HC; }
^{A}{U}{T}{H}{E}{N}{T}{I}{C}{A}{T}{I}{O}{N}-{I}{N}{F}{O}{HC} { updloc(); return AUTHENTICATION_INFO_HC; }
^{A}{U}{T}{H}{O}{R}{I}{Z}{A}{T}{I}{O}{N}{HC}	{ updloc(); return AUTHORIZATION_HC; }
^{C}{A}{L}{L}-{I}{D}{HC}		 	{ updloc(); return CALL_ID_HC; }
^{I}{HC}  			 		{ updloc(); return CALL_ID_HC; }
^{C}{A}{L}{L}-{I}{N}{F}{O}{HC}	 		{ updloc(); return CALL_INFO_HC; }
^{C}{O}{N}{T}{A}{C}{T}{HC}	 		{ updloc(); return CONTACT_HC; }
^{M}{HC}		 			{ updloc(); return CONTACT_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{D}{I}{S}{P}{O}{S}{I}{T}{I}{O}{N}{HC} { updloc(); return CONTENT_DISPOSITION_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{E}{N}{C}{O}{D}{I}{N}{G}{HC} { updloc(); return CONTENT_ENCODING_HC; }
^{E}{HC}  			 		{ updloc(); return CONTENT_ENCODING_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{L}{A}{N}{G}{U}{A}{G}{E}{HC} { updloc(); return CONTENT_LANGUAGE_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{L}{E}{N}{G}{T}{H}{HC} 	{ updloc(); return CONTENT_LENGTH_HC; }
^{L}{HC}  			 		{ updloc(); return CONTENT_LENGTH_HC; }
^{C}{O}{N}{T}{E}{N}{T}-{T}{Y}{P}{E}{HC} 	{ updloc(); return CONTENT_TYPE_HC; }
^{C}{HC}			 		{ updloc(); return CONTENT_TYPE_HC; }
^{C}{S}{E}{Q}{HC}			 	{ updloc(); return CSEQ_HC; }
^{D}{A}{T}{E}{HC}			 	{ updloc(); return DATE_HC; }
^{E}{R}{R}{O}{R}-{I}{N}{F}{O}{HC}	 	{ updloc(); return ERROR_INFO_HC; }
^{E}{X}{P}{I}{R}{E}{S}{HC} 		 	{ updloc(); return EXPIRES_HC; }
^{F}{R}{O}{M}{HCOLON}	 	 		{ updloc(); return FROM_HC; }
^{F}{HC}		 			{ updloc(); return FROM_HC; }
^{I}{N}-{R}{E}{P}{L}{Y}-{T}{O}{HC}  		{ updloc(); return IN_REPLY_TO_HC; }
^{M}{A}{X}-{F}{O}{R}{W}{A}{R}{D}{S}{HC}	  	{ updloc(); return MAX_FORWARDS_HC; }
^{M}{I}{M}{E}-{V}{E}{R}{S}{I}{O}{N}{HC}  	{ updloc(); return MIME_VERSION_HC; }
^{M}{I}{N}-{E}{X}{P}{I}{R}{E}{S}{HC} 		{ updloc(); return MIN_EXPIRES_HC; }
^{O}{R}{G}{A}{N}{I}{Z}{A}{T}{I}{O}{N}{HC}	{ updloc(); return ORGANIZATION_HC; }
^{P}{R}{I}{O}{R}{I}{T}{Y}{HC}  		 	{ updloc(); return PRIORITY_HC; }
^{P}{R}{O}{X}{Y}-{A}{U}{T}{H}{E}{N}{T}{I}{C}{A}{T}{E}{HC} { updloc(); return PROXY_AUTHENTICATE_HC; }
^{P}{R}{O}{X}{Y}-{A}{U}{T}{H}{O}{R}{I}{Z}{A}{T}{I}{O}{N}{HC} { updloc(); return PROXY_AUTHORIZATION_HC; }
^{P}{R}{O}{X}{Y}-{R}{E}{Q}{U}{I}{R}{E}{HC}	{ updloc(); return PROXY_REQUIRE_HC; }
^{R}{E}{C}{O}{R}{D}-{R}{O}{U}{T}{E}{HC} 	{ updloc(); return RECORD_ROUTE_HC; }
^{R}{E}{P}{L}{Y}-{T}{O}{HC}	 		{ updloc(); return REPLY_TO_HC; }
^{R}{E}{Q}{U}{I}{R}{E}{HC}  		 	{ updloc(); return REQUIRE_HC; }
^{R}{E}{T}{R}{Y}-{A}{F}{T}{E}{R}{HC}  		{ updloc(); return RETRY_AFTER_HC; }
^{R}{O}{U}{T}{E}{HC} 		 		{ updloc(); return ROUTE_HC; }
^{S}{E}{R}{V}{E}{R}{HC}		 		{ updloc(); return SERVER_HC; }
^{S}{U}{B}{J}{E}{C}{T}{HC} 		 	{ updloc(); return SUBJECT_HC; }
^{S}{HC}  			 		{ updloc(); return SUBJECT_HC; }
^{S}{U}{P}{P}{O}{R}{T}{E}{D}{HC}  		{ updloc(); return SUPPORTED_HC; }
^{K}{HC}  			 		{ updloc(); return SUPPORTED_HC; }
^{T}{I}{M}{E}{S}{T}{A}{M}{P}{HC}  		{ updloc(); return TIMESTAMP_HC; }
^{T}{O}{HC}  		 			{ updloc(); return TO_HC; }
^{T}{HC}  		 			{ updloc(); return TO_HC; }
^{U}{N}{S}{U}{P}{P}{O}{R}{T}{E}{D}{HC}  	{ updloc(); return UNSUPPORTED_HC; }
^{U}{S}{E}{R}_{A}{G}{E}{N}{T}{HC}	 	{ updloc(); return USER_AGENT_HC; }
^{V}{I}{A}{HC}  			 	{ updloc(); return VIA_HC; }
^{V}{HC}  			 		{ updloc(); return VIA_HC; }
^{W}{A}{R}{N}{I}{N}{G}{HC}  		 	{ updloc(); return WARNING_HC; }
^{W}{W}{W}-{A}{U}{T}{H}{E}{N}{T}{I}{C}{A}{T}{E}{HC} { updloc(); return WWW_AUTHENTICATE_HC; }
^({ALPHA}|{DIGIT})+{HC}				{ updloc(); return HEADER_NAME_HC; }


<nrml>{D}{I}{G}{E}{S}{T}{LWS}  	    		{ updloc(); return DIGEST_LWS; }

<nrml>{D}{U}{R}{A}{T}{I}{O}{N}{SWS}={SWS}   	{ updloc(); return DURATION_E; }
<nrml>{U}{S}{E}{R}{N}{A}{M}{E}{SWS}={SWS}   	{ updloc(); return USERNAME_E; }
<nrml>{U}{R}{I}{SWS}={SWS}	    		{ updloc(); return URI_E; }
<nrml>{H}{A}{N}{D}{L}{I}{N}{G}{SWS}={SWS}   	{ updloc(); return HANDLING_E; } 
<nrml>{P}{U}{R}{P}{O}{S}{E}{SWS}={SWS}    	{ updloc(); return PURPOSE_E; }
<nrml>{N}{E}{X}{T}{N}{O}{N}{C}{E}{SWS}={SWS}  	{ updloc(); return NEXTNONCE_E; }
<nrml>{R}{S}{P}{A}{U}{T}{H}{SWS}={SWS}    	{ updloc(); return RSPAUTH_E; }
<nrml>{R}{E}{S}{P}{O}{N}{S}{E}{SWS}={SWS}   	{ updloc(); return RESPONSE_E; }
<nrml>{C}{N}{O}{N}{C}{E}{SWS}={SWS}	    	{ updloc(); return CNONCE_E; }
<nrml>{N}{C}{SWS}={SWS}	    			{ updloc(); return NC_E; }
<nrml>{Q}{O}{P}{SWS}={SWS} 	    		{ updloc(); return QOP_E; }
<nrml>{R}{E}{A}{L}{M}{SWS}={SWS} 	    	{ updloc(); return REALM_E; }
<nrml>{D}{O}{M}{A}{I}{N}{SWS}={SWS}     	{ updloc(); return DOMAIN_E; }
<nrml>{N}{O}{N}{C}{E}{SWS}={SWS} 	    	{ updloc(); return NONCE_E; }
<nrml>{O}{P}{A}{Q}{U}{E}{SWS}={SWS}     	{ updloc(); return OPAQUE_E; }
<nrml>{S}{T}{A}{L}{E}{SWS}={SWS}{F}{A}{L}{S}{E} { updloc(); return STALE_E_TRUE; }
<nrml>{S}{T}{A}{L}{E}{SWS}={SWS}{T}{R}{U}{E}  	{ updloc(); return STALE_E_FALSE; }

<nrml>{A}{L}{G}{O}{R}{I}{T}{H}{M}{SWS}={SWS}  	{ updloc(); return ALGORITHM_E; }
<nrml>{T}{T}{L}{SWS}={SWS} 	    		{ updloc(); return TTL_E; }
<nrml>{M}{A}{D}{D}{R}{SWS}={SWS}      		{ updloc(); return MADDR_E; }
<nrml>{R}{E}{C}{E}{I}{V}{E}{D}{SWS}={SWS}  	{ updloc(); return RECEIVED_E; }
<nrml>{B}{R}{A}{N}{C}{H}{SWS}={SWS}	    	{ updloc(); return BRANCH_E; }


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


 /* special literals, etc. */
"'"  		{ updloc(); return SHCOMMA; } 
\\   		{ updloc(); return SBSLASH; }
\"   		{ updloc(); return SDQUOTE; }
" "  		{ updloc(); return SP; } 
[\t] 		{ updloc(); return HTAB; }
{LWS}		{ updloc(); return LWS; }


 /* for fixing lws-ambiguity-problem */
{LWS}{LWS}		{ updloc(); return LWSSQR; }
>{LWS}			{ updloc(); return RAQUOT; };
{LWS}?*{LWS}? 		{ updloc(); return STAR; }
{LWS}?\/{LWS}? 		{ updloc(); return SLASH; }
{LWS}?={LWS}? 		{ updloc(); return EQUAL; }
{LWS}?\({LWS}? 		{ updloc(); return LPAREN; }
{LWS}?\){LWS}? 		{ updloc(); return RPAREN; }
{LWS}?,{LWS}? 		{ updloc(); return COMMA; }
{LWS}?;{LWS}? 		{ updloc(); return SEMI; }
{LWS}?:{LWS}? 		{ updloc(); return COLON; }

{LWS}\"			{ updloc(); return LWS_SDQUOTE; }
\"{LWS}			{ updloc(); return SDQUOTE_LWS; }

{ALPHA} 	{ updloc(); return ALPHA; };
{DIGIT} 	{ updloc(); return DIGIT; };

[\n] {
  // location-update
    yylloc.first_line   = yylloc.last_line=yylineno;
    yylloc.first_column = yylloc.last_column=1;
  return CRLF;
}
%%

#ifndef yywrap
int yywrap() {
  return 1;
}
#endif

