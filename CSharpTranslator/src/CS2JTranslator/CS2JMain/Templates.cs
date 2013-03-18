/*
   Copyright 2010-2013 Kevin Glynn (kevin.glynn@twigletsoftware.com)
   Copyright 2007-2013 Rustici Software, LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT/X Window System License

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the MIT/X Window System License
along with this program.  If not, see 

   <http://www.opensource.org/licenses/mit-license>
*/

using System;

namespace Twiglet.CS2J.Translator
{
    public class Templates
    {

        private static string _javaTemplateGroup = @"
// version 1.1

group JavaPrettyPrintTemplates;

itsmine(now, includeDate) ::= <<
<if(includeDate)>
//
// Translated by CS2J (http://www.cs2j.com): <now><\n>
<endif>
//

>>

package(now, includeDate, packageName, imports, comments, modifiers, type, endComments) ::= <<
<itsmine(now=now,includeDate=includeDate)>
<if(packageName)>package <packageName>;<endif>

<comments; separator=""\n"">
<imports>

<type>

<endComments; separator=""\n"">
>>

import_list(nss) ::= <<
<nss:{x | import <x>;}; separator=""\n"">
>>

import_template(ns) ::= ""import <ns>;""

// ******* CLASSES ***********

class(modifiers, comments, attributes, type, name, typeparams, extends, imps, body, partial_types, end_comments) ::= <<
<comments; separator=""\n"">
<modifiers><if(type)><type><else>class<endif> <name> <typeparams> <extends> <imps>
{
    <body>
    <partial_types>
}
<end_comments; separator=""\n"">
>>

class_body(entries) ::= <<
<entries; separator=""\n"">
>>

class_member(comments, member) ::= <<
<comments; separator=""\n"">
<member>
>>

constructor(modifiers, name, params, exceptions, body, bodyIsSemi) ::= <<
<modifiers><name>(<params; separator="", "">)<if(exceptions)> throws <exceptions; separator="", ""><endif> <if(bodyIsSemi)>;
<else>
<body>
<endif>
<\n>
>>

static_constructor(modifiers, body, bodyIsSemi) ::= <<
<modifiers><if(bodyIsSemi)>;
<else>
<body>
<endif>
<\n>
>>

method(modifiers, typeparams, type, name, params, exceptions, body, bodyIsSemi) ::= <<
<modifiers><typeparams><type> <name>(<params>)<if(exceptions)> throws <exceptions; separator="", ""><endif> <if(bodyIsSemi)>;
<else>
<body>
<endif>
<\n>
>>

field(modifiers, type, field, comments, init) ::= ""<comments><modifiers><type> <field>;""

variable_declarators(varinits) ::= ""<varinits; separator=\"", \"">""
variable_declarator(typename,init) ::= ""<typename><if(init)> = <init><endif>"" 

primary_expression_start_parts(start,follows) ::= ""<start><follows>""

type_param_constraint(param, constraints) ::= ""<param> extends <constraints; separator=\"" & \"">""

fixed_parameter(mod,type,name,def) ::= <<
<mod><type> <name><if(def)> = <def><endif>
>>

varargs(type,name) ::= <<
<type>... <name>
>>

identifier(id, id2) ::= ""<id><if(id2)>::<id2><endif>""

statement_list(statements) ::= <<
<statements; separator=""\n"">
>>

statement(statement) ::= <<
<statement>
>>

annotation(modifiers, comments, attributes, name, body) ::= <<
<comments; separator=""\n"">
<modifiers>@interface <name>
{
    <body>
}
>>

//***** local var declarations:

local_variable_declaration(type,decs) ::= ""<type> <decs>""
local_variable_declarator(name, init) ::= ""<name><if(init)> = <init><endif>""

return(exp) ::= ""return <exp>;""
throw(exp) ::= ""throw <exp>;""

// ******* ENUMS ***********

enum(modifiers,comments, attributes, name, body) ::= <<
<comments; separator=""\n"">
<modifiers>enum <name>
{
    <body>
}
>>

enum_body(values) ::= ""<values; separator=\"",\n\"">""

enum_member(comments, value) ::= <<
<comments; separator=""\n"">
<value>
>>

type(name, rs, stars, opt) ::= ""<name><rs><stars><opt>""
namespace_or_type(type1, type2, types) ::= ""<type1><if(type2)>::<type2><endif><if(types)>.<types; separator=\"".\""><endif>""

modifiers(mods) ::= <<
<if(mods)><mods; separator="" ""> <endif>
>>

type_parameter_list(items) ::= <<
\<<items; separator="", "">\>
>>

extends(types) ::= ""<if(types)>extends <types; separator=\"", \""><endif>""
imps(types) ::= ""<if(types)>implements <types; separator=\"", \""><endif>""

// ******* STATEMENTS *******
if_template(comments, cond, then, thenindent, else, elseindent, elseisif) ::= <<
<comments; separator=""\n"">
if (<cond>)
<block(statements = then, indent = thenindent)>
<if(else)>
else<if(elseisif)> <block(statements = else)><else>

<block(statements = else, indent = elseindent)>
<endif>
<endif> 
>>

while(comments,cond,block) ::= <<
<comments; separator=""\n"">
while (<cond>)
<block(statements = block)>
>>

do(comments,cond,block) ::= <<
<comments; separator=""\n"">
do
<block(statements = block)>
while (<cond>);
>>

for(comments,init,cond,iter,block,blockindent) ::= <<
<comments; separator=""\n"">
for (<init>;<cond>;<iter>)
<block(statements = block, indent=blockindent)>
>>

foreach(comments,type,loopid,fromexp,block,blockindent) ::= <<
<comments; separator=""\n"">
for (<type> <loopid> : <fromexp>)
<block(statements = block,indent=blockindent)>
>>

try(comments,block, blockindent, catches, fin) ::= <<
<comments; separator=""\n"">
try
<block(statements = block, indent=blockindent)>
<catches>
<fin>
>>

catch_template(type, id, block, blockindent) ::= <<
catch (<type> <id>)
<block(statements = block, indent = blockindent)>
>>

fin(block, blockindent) ::= <<
finally
<block(statements = block, indent = blockindent)>
>>


switch(comments,scrutinee, sections) ::= <<
<comments; separator=""\n"">
switch(<scrutinee>)
{
    <sections>
}
>>

switch_section(labels,statements) ::= <<
<labels; separator=""\n"">
    <statements; separator=""\n"">

>>

case(what) ::= <<
case <what>: 
>>

default_template() ::= <<
default: 
>>

synchstat(comments,exp,stat) ::= <<
<comments; separator=""\n"">
synchronized (<exp>)
<block(statements = stat, indent = indent)>
>>

yield(comments,exp) ::= <<
<comments; separator=""\n"">
yield <if(exp)>return <exp><else>break<endif>;
>>

keyword_block(comments,keyword,block, indent) ::= <<
<comments; separator=""\n"">
<keyword>
<block(statements = block, indent = indent)>
>>

block(statements, indent) ::= <<
<if(indent)>
    <statements>
<else>
<statements>
<endif>
>>

braceblock(statements) ::= <<
{
    <statements; separator=""\n"">
}
>>

// ******* EXPRESSIONS *******

cast_expr(type, exp) ::= ""(<type>)<exp>""
construct(type, args, inits) ::= ""new <type>(<args>)<if(inits)> /* [UNIMPLEMENTED] <inits> */<endif>""
delegate(type, args, body) ::= <<
new <type>(<args>) 
  { 
    <body>
  }
>>
lambda(args, body) ::= <<
(<args>) => <body>
>>
array_construct(type, args, inits) ::= ""new <type>[<if(args)><args><endif>]<if(inits)><inits><endif>""
array_construct_nobracks(type, inits) ::= ""new <type><if(inits)><inits><endif>""
array_initializer(init) ::= ""{ <init> }""
application(func, funcparens, args) ::= ""<optparens(parens=funcparens,e=func)>(<args>)"" 
index(func, funcparens, args) ::= ""<optparens(parens=funcparens,e=func)>[<args>]"" 
stackalloc(type, exp) ::= ""stackalloc <type>[<exp>]""
typeof(type) ::= ""<type>.class""

cond(condexp,condparens,thenexp,thenparens,elseexp,elseparens) ::= <<
<if(condparens)>(<endif><condexp><if(condparens)>)<endif> ? <if(thenparens)>(<endif><thenexp><if(thenparens)>)<endif> : <if(elseparens)>(<endif><elseexp><if(elseparens)>)<endif>
>>

// ******* TYPES ***********
void() ::= ""void""

// ******* MISC ***********

optparens(parens, e) ::= ""<if(parens)>(<endif><e><if(parens)>)<endif>""
parens(e) ::= ""(<e>)""
rank_specifiers(rs) ::= ""<rs>""
op(comments,pre,op,post,preparen,postparen,space) ::= <<
<comments; separator=""\n"">
<if(pre)><if(preparen)>(<endif><pre><if(preparen)>)<endif><space><endif><op><if(post)><space><if(postparen)>(<endif><post><if(postparen)>)<endif><endif>
>>
member_access(comments,pre,op,access,access_tyargs,preparen) ::= <<
<comments; separator=""\n"">
<if(preparen)>(<endif><pre><if(preparen)>)<endif><op><access_tyargs><access>
>>
assign(lhs,lhsparen,assign,rhs,rhsparen) ::= ""<if(lhsparen)>(<endif><lhs><if(lhsparen)>)<endif> <assign> <if(rhsparen)>(<endif><rhs><if(rhsparen)>)<endif>""
generic_args(args) ::= ""\<<args>\>""
parameter(annotation,param) ::=  ""/* <annotation> */ <param>""
inline_comment(payload, explanation) ::= ""/* <explanation> <payload> */""
commalist(items) ::= ""<items; separator=\"", \"">""
dotlist(items) ::= ""<items; separator=\"".\"">""
//list(items,sep) ::= ""<items;separator=sep>""
list(items,sep) ::= <<
<items;separator=sep>
>>
seplist(items,sep) ::= <<
<items;separator=sep>
>>

unsupported(reason, text) ::= ""/* [UNSUPPORTED] <reason> \""<text>\"" */""


// ******* UTILITY ***********
string(payload) ::= ""<payload>""

verbatim_string(payload) ::= <<
""<payload; separator=""\"" + \n\"""">""
>>

";

	public static string JavaTemplateGroup { get
                { return _javaTemplateGroup; }
        }
    }
}

