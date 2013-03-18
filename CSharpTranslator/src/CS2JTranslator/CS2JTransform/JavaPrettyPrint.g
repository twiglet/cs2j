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

tree grammar JavaPrettyPrint;

options {
    tokenVocab=cs;
    ASTLabelType=CommonTree;
    language=CSharp2;
    superClass='Twiglet.CS2J.Translator.Transform.CommonWalker';
    output=template;
}

// We don't emit partial types as soon as we generate them, we merge them unti we know we hve seen all parts
scope TypeContext {
    Dictionary<string,ClassDescriptorSerialized> partialTypes;
}

@namespace { Twiglet.CS2J.Translator.Transform }

@header
{
	using System;
	using System.IO;
	using System.Xml;
	using System.Xml.Xsl;
	using System.Collections;
	using System.Text;
	using System.Text.RegularExpressions;
}

@members
{

    public bool IsLast { get; set; }
    public int EmittedCommentTokenIdx { get; set; }
    // If top level is partial then this will contain the components so that we can mere with other parts down the line
    public ClassDescriptorSerialized PartialDescriptor { get; set; }

	protected string convertToJavaDoc(string docComment) {
		string ret = null;
		try {
            StringBuilder javaDocStr = new StringBuilder();

			string xml = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<root>" + docComment + "\n</root>";

			// Encode the XML string in a UTF-8 byte array
			byte[] encodedString = Encoding.UTF8.GetBytes(xml);

			// Put the byte array into a stream and rewind it to the beginning
			MemoryStream ms = new MemoryStream(encodedString);
			ms.Flush();
			ms.Position = 0;

			// Build the XmlDocument from the MemorySteam of UTF-8 encoded bytes
			XmlDocument xmlDoc = new XmlDocument();
			xmlDoc.Load(ms);

            JdXslTrans.Transform(xmlDoc,null,new StringWriter(javaDocStr));
            ret = javaDocStr.ToString().Trim().Replace("\n", "\n* ");
            ret = String.Format("/**\n* {0}\n*/", ret);
        }
		catch (Exception) 
		{
			// skip, just return null
		}
		return ret;
	}
    
	private List<string> collectedComments = null;
    List<string> CollectedComments {
        get {
   
            List<string> rets = new List<string>(); 
            if (collectedComments != null) {
				List<string> savedComments = new List<string>();
				bool inDoc = false;
				string xmlDoc = "";
				foreach (string c in collectedComments) {
					string line = processComment(c);
				    if (Cfg.TranslatorMakeJavadocComments && line.TrimStart().StartsWith("///")) {
						inDoc = true;
						savedComments.Add(line);
						xmlDoc += line.TrimStart().Substring(3).TrimStart() + "\n";
					}
					else 
					{
					    if (inDoc) {
							string javaDoc = convertToJavaDoc(xmlDoc);
						    if (javaDoc != null) {
								rets.Add(javaDoc);
							} 
                            else {
                               rets.AddRange(savedComments); 
                           }
							savedComments = new List<string>();
							inDoc = false;
							xmlDoc = "";
						}
						rets.Add(line);
					}
                }
				if (inDoc) {
                   string javaDoc = convertToJavaDoc(xmlDoc);
                   if (javaDoc != null) {
                      rets.Add(javaDoc);
                   } 
                   else {
                      rets.AddRange(savedComments); 
                   }
				}
            }

            collectedComments = null;
            
            return rets;
        }
        set {
            if (collectedComments == null) 
                collectedComments = new List<string>();
            foreach (string c in value) {
                collectedComments.Add(c);
            }
        }
    }
        
        // substitute \\u for \u, java searches for unicode in comments so you can have an error in a comment!
        // In time, we will convert C# doc comments to javadoc
        private string processComment(string c)
        {
            return Regex.Replace(c, "([^\\\\])\\\\u","$1\\\\u");
        }

    // Collect all comments from previous position to endIdx
    // comments are the text from tokens on the Hidden channel
    protected void collectComments(IToken tok) {
        // TokenIndex may be -1, no sweat we just won't collect anything
        collectComments(tok.TokenIndex);
    }
    protected void collectComments(int endIdx) {
        List<string> rets = new List<string>();
        List<IToken> toks = ((CommonTokenStream)this.GetTreeNodeStream().TokenStream).GetTokens(EmittedCommentTokenIdx,endIdx);
        if (toks != null) {
            foreach (IToken tok in toks) {
                if (tok.Channel == TokenChannels.Hidden) {
                    rets.Add(new Regex("(\\n|\\r)+").Replace(tok.Text, Environment.NewLine).Trim());
                }
            }
            EmittedCommentTokenIdx = endIdx+1;
        }
        CollectedComments = rets;
    }

    protected void collectComments() {
        collectComments(((CommonTokenStream)this.GetTreeNodeStream().TokenStream).GetTokens().Count - 1);
    }

    protected List<string> escapeJavaString(string rawStr)
    {
        List<string> rets = new List<string>();
        StringBuilder buf = new StringBuilder();
        bool seenDQ = false;
        foreach (char ch in rawStr)
        {
            switch (ch)
            {
            case '\\':
                buf.Append("\\\\");
                break;
            case '"':
                if (seenDQ)
                    buf.Append("\\\"");
                seenDQ = !seenDQ;
                break;
            case '\'':
                buf.Append("\\'");
                break;
            case '\b':
                buf.Append("\\b");
                break;
            case '\t':
                buf.Append("\\t");
                break;
            case '\n':
                buf.Append("\\n");
                rets.Add(buf.ToString());
                buf = new StringBuilder();
                break;
            case '\f':
                buf.Append("\\f");
                break;
            case '\r':
                buf.Append("\\r");
                break;
            default:
                buf.Append(ch);
                break;
            }
            if (ch != '"')
                seenDQ = false;
        }
        if (buf.Length > 0) {
           rets.Add(buf.ToString());
        }
        return rets;
    }

    // keving:  Found this precedence table on the ANTLR site.
    
    /** Encodes precedence of various operators; indexed by token type.
     *  If precedence[op1] > precedence[op2] then op1 should happen
     *  before op2;
     * table from http://www.cs.princeton.edu/introcs/11precedence/ 
     */
    private int[] precedence = new int[tokenNames.Length];
    private bool precedenceInitted = false;
    protected bool IsPrecedenceInitted {
        get { return precedenceInitted; }
        set { precedenceInitted = value; }
    }
    private void initPrecedence()
    {
        if (IsPrecedenceInitted) 
            return;

        for (int i=0; i<precedence.Length; i++) {
            // anything but these operators binds super tight
            // for example METHOD_CALL binds tighter than PLUS
            precedence[i] =  int.MaxValue;
        }
        precedence[ASSIGN] = 1;
        precedence[LAMBDA] = 1;
        precedence[PLUS_ASSIGN] = 1;
        precedence[MINUS_ASSIGN] = 1;
        precedence[STAR_ASSIGN] = 1;
        precedence[DIV_ASSIGN] = 1;
        precedence[MOD_ASSIGN] = 1;
        precedence[RIGHT_SHIFT_ASSIGN] = 1;
        precedence[LEFT_SHIFT_ASSIGN] = 1;
        precedence[UNSIGNED_RIGHT_SHIFT_ASSIGN] = 1;
        precedence[BIT_AND_ASSIGN] =1;
        precedence[BIT_XOR_ASSIGN] = 1;
        precedence[BIT_OR_ASSIGN] = 1;

        precedence[COND_EXPR] = 2;

        precedence[LOG_OR] = 3;

        precedence[LOG_AND] = 4;

        precedence[BIT_OR] = 5;

        precedence[BIT_XOR] = 6;

        precedence[BIT_AND] = 7;

        precedence[NOT_EQUAL] = 8;
        precedence[EQUAL] = 8;

        precedence[LTHAN] = 9;
        precedence[GT] = 9;
        precedence[LTE] = 9;
        precedence[GTE] = 9;
        precedence[INSTANCEOF] = 9;
        
        precedence[LEFT_SHIFT] = 10;
        precedence[RIGHT_SHIFT] = 10;
        precedence[UNSIGNED_RIGHT_SHIFT] = 10;

        precedence[PLUS] = 11;
        precedence[MINUS] = 11;
 
        precedence[DIV] = 12;
        precedence[MOD] = 12;
        precedence[STAR] = 12;
         
        precedence[CAST_EXPR] = 13;
        precedence[NEW] = 13;
 
        precedence[PREINC] = 14;
        precedence[PREDEC] = 14;
        precedence[MONONOT] = 14;
        precedence[MONOTWIDDLE] = 14;
        precedence[MONOMINUS] = 14;
        precedence[MONOPLUS] = 14;
 
        precedence[POSTINC] = 15;
        precedence[POSTDEC] = 15;   
        precedence[APPLY] = 16;   
        precedence[INDEX] = 16;   
        precedence[DOT] = 16;   

        IsPrecedenceInitted = true;
     }


    // Compares precedence of op1 and op2. 
    // Returns -1 if op2 < op1
    //	        0 if op1 == op2
    //          1 if op2 > op1
    public int comparePrecedence(IToken op1, IToken op2) {
        return Math.Sign(precedence[op2.Type]-precedence[op1.Type]);
    }
    public int comparePrecedence(IToken op1, int childPrec) {
        return Math.Sign(childPrec-precedence[op1.Type]);
    }
    public int comparePrecedence(int parentPrec, int childPrec) {
        return Math.Sign(childPrec-parentPrec);
    }
    // cleverly remove any remaining ${..} tokens
    public string cleanTemplate(string template) {
        // Are there any markers in the template? Mostly, the answer will be no and we can return tout-de-suite
        string ret = template;
        if (Regex.IsMatch(ret, "\\$\\{[\\w:]+\\}")) {
            // ${this}.fred -> fred
            ret = Regex.Replace(ret, "\\$\\{[\\w:]+?\\}\\.", String.Empty);
            // (a,${var},b) -> (a,b)
            ret = Regex.Replace(ret, "\\$\\{[\\w:]+?\\}\\s*,", String.Empty);
            // (a,${var}) -> (a)
            ret = Regex.Replace(ret, ",\\s*\\$\\{[\\w:]+?\\}", String.Empty);
            // (${var}) -> ()
            ret = Regex.Replace(ret, "\\$\\{[\\w:]+?\\}", String.Empty);
            // ${,?.+,?} ->
            ret = Regex.Replace(ret, "\\$\\{,?[^\\}]+?,?\\}", String.Empty);
        }
        // If we have a generic type then we can scrub its generic arguments
        // by susbstituting with an empty dictionary, now tidy up the brackets
        // and commas
        ret = Regex.Replace(ret, "\\s*<(\\s*,\\s*)*>\\s*", String.Empty);
        return ret;
    }

    //
    public class ReplacementDescriptor {
        private string replacementText = "";
        private IList<StringTemplate> replacementTextList = null;
        private int replacementPrec = -1;
        public ReplacementDescriptor(string txt, int prec)
        {
            replacementText = txt;
            replacementPrec = prec;
        }
        public ReplacementDescriptor(string txt)
        {
            replacementText = txt;
            replacementPrec = Int32.MaxValue;
        }

        public ReplacementDescriptor(IList<StringTemplate> txts)
        {
            replacementTextList = txts == null ? new List<StringTemplate>() : txts;
            replacementPrec = Int32.MaxValue;
        }

        public string replace(Match m) {
            // Console.Out.WriteLine("prec: {0} {1} {2} {3}", m.Value, m.Groups.Count, m.Groups[0], m.Groups[1]);
            if (!String.IsNullOrEmpty(m.Groups[2].Value) && replacementTextList != null) {
               // pattern has form ${(,)?v](n)(:p)?(,)?}
               StringBuilder txtBuf = new StringBuilder();
               bool first = true;
               for (int idx = Int32.Parse(m.Groups[2].Value); idx < replacementTextList.Count; idx++) {
                  String argTxt = replacementTextList[idx] == null ? String.Empty : replacementTextList[idx].ToString();
                  if (!first)
                     txtBuf.Append(",");
                  txtBuf.Append(argTxt);
                  first = false;
               }
               if (txtBuf.Length > 0) {
                  if (!String.IsNullOrEmpty(m.Groups[1].Value))
                     txtBuf.Insert(0,",");
                  if (!String.IsNullOrEmpty(m.Groups[4].Value))
                     txtBuf.Append(",");
               }
               return txtBuf.ToString();
            }
            else {
               int patternPrec = (String.IsNullOrEmpty(m.Groups[3].Value) ? -1 : Int32.Parse(m.Groups[3].Value));
               return String.Format("{0}" + (replacementPrec < patternPrec ? "({1})" : "{1}") + "{2}", 
                                    !String.IsNullOrEmpty(m.Groups[1].Value) ? "," : String.Empty,
                                    replacementText,
                                    !String.IsNullOrEmpty(m.Groups[4].Value) ? "," : String.Empty
                                    );
            }
        }
    }

    public string fillTemplate(string template, Dictionary<string,ReplacementDescriptor> templateMap) {
        string ret = template;
        // *[ -> < and ]* -> >
        ret = ret.Replace("*[","<").Replace("]*",">");
        foreach (string v in templateMap.Keys) {
            MatchEvaluator myEvaluator = new MatchEvaluator(templateMap[v].replace);
            ret = Regex.Replace(ret, "\\$\\{(,)?" + Regex.Escape(v) + "(?:\\](\\d+))?(?::(\\d+))?(,)?}", myEvaluator);
        }
        ret = cleanTemplate(ret);
        return ret;
    }

    protected string mkString(object s) {
       return (s == null ? String.Empty : s.ToString()); 
    }
    
    protected void mergeParts(ClassDescriptorSerialized master, ClassDescriptorSerialized part) {
       // Merge into existing descriptor 
       if (!String.IsNullOrEmpty(part.Comments)) {
          master.Comments += "\n" + part.Comments;
       }
       if (!String.IsNullOrEmpty(part.EndComments)) {
          master.EndComments += "\n" + part.EndComments;
       }

       // So that we can set "class" as default an doverride it when we see its an interface
       master.Type = part.Type;

       // Union all attributes
       // we don't push through attributes yet
       master.Atts += part.Atts;

       // Merge modifiers
       foreach (string m in part.Mods) {
          if (!master.Mods.Contains(m)) {
             master.Mods.Add(m);
          }
       }

       if (String.IsNullOrEmpty(master.TypeParameterList)) {
          master.TypeParameterList = part.TypeParameterList;
       }

       foreach (string m in part.ClassExtends) {
          if (!master.ClassExtends.Contains(m)) {
             master.ClassExtends.Add(m);
          }
       }

       foreach (string m in part.ClassImplements) {
          if (!master.ClassImplements.Contains(m)) {
             master.ClassImplements.Add(m);
          }
       }

       // Union the class bodies
       if (!String.IsNullOrEmpty(part.ClassBody)) {
          master.ClassBody += "\n" + part.ClassBody;
       }

       foreach (KeyValuePair<String,ClassDescriptorSerialized> d in part.PartialTypes) {
          if (master.PartialTypes.ContainsKey(d.Key)) {
             mergeParts(master.PartialTypes[d.Key], part.PartialTypes[d.Key]);
          }
          else {
             master.PartialTypes[d.Key] = part.PartialTypes[d.Key];
          }
       }

    }

    public StringTemplate emitPackage(ClassDescriptorSerialized part)
    {
          
       // Pretty print as text
       StringTemplate pkgST = %package();
       %{pkgST}.now = DateTime.Now; 
       %{pkgST}.includeDate = Cfg.TranslatorAddTimeStamp; 
       %{pkgST}.packageName = part.Package;
       StringTemplate impST = %import_list();
       %{impST}.nss = part.Imports;
       %{pkgST}.imports = impST;
       %{pkgST}.type = emitPartialType(part);
       %{pkgST}.endComments = part.EndComments;
 
       return pkgST;
    }

    public StringTemplate emitPartialType(ClassDescriptorSerialized part)
    {
          
       // Pretty print as text
       StringTemplate modST = %modifiers();
       %{modST}.mods = part.Mods; 
       StringTemplate serTy = %class();
       %{serTy}.comments = part.Comments; 
       %{serTy}.modifiers = modST;
       %{serTy}.type = part.Type; 
       %{serTy}.name = part.Identifier; 
       %{serTy}.typeparams = part.TypeParameterList;
       StringTemplate extTy = %extends();
       %{extTy}.types = part.ClassExtends; 
       %{serTy}.extends = extTy; 
       StringTemplate impsTy = %imps();
       %{impsTy}.types = part.ClassImplements; 
       %{serTy}.imps = impsTy; 
       %{serTy}.body = part.ClassBody; 
       %{serTy}.partial_types = emitParts(part.PartialTypes); 
       %{serTy}.end_comments = part.EndComments; 
       return serTy;
    }

    protected StringTemplate emitParts(Dictionary<string, ClassDescriptorSerialized> partialTypes)
    {
          
       // Pretty print as text
       List<StringTemplate> serParts = new List<StringTemplate>();
       foreach (ClassDescriptorSerialized part in partialTypes.Values) {
          StringTemplate partST = emitPartialType(part);
          serParts.Add(partST);
       }
       StringTemplate allParts = %seplist();
       %{allParts}.items = serParts;
       %{allParts}.sep = "\n";

       return allParts;
    }

}

public compilation_unit
scope TypeContext;
@init{
    initPrecedence();
    $TypeContext::partialTypes = new Dictionary<string,ClassDescriptorSerialized>();
}
:
    ^(PACKAGE nm=PAYLOAD imports? type_declaration) 

      {
         if (IsLast) collectComments(); 
         if (PartialDescriptor != null && $TypeContext::partialTypes.Count > 0) {
            // Merge into existing descriptor (must only be one)
            foreach (ClassDescriptorSerialized part in $TypeContext::partialTypes.Values) {
               mergeParts(PartialDescriptor, part);
            }

            // If this is the first time we have seen thsi we must ensure Package name is there
            PartialDescriptor.Package = ($nm.text != null && $nm.text.Length > 0 ? $nm.text : null);
            if ($imports.importList != null && $imports.importList.Count > 0) {
               foreach (string m in $imports.importList) {
                  if (!PartialDescriptor.Imports.Contains(m)) {
                     PartialDescriptor.Imports.Add(m);
                  }
               }
            }
            if (IsLast) {
               List<string> endComments = CollectedComments;
               if (endComments != null) {
                  foreach (string comment in endComments) {
                     PartialDescriptor.EndComments += comment;
                  }
               }
            }
  
         }
      }
    -> { PartialDescriptor != null}? // output is all collected in PartialDescriptor 
    -> 
        package(now = {DateTime.Now}, includeDate = {Cfg.TranslatorAddTimeStamp}, packageName = {($nm.text != null && $nm.text.Length > 0 ? $nm.text : null)},
            imports = {$imports.st},
            type = {$type_declaration.st},
            endComments = { CollectedComments });

type_declaration:
    class_declaration[true] -> { $class_declaration.st }
	| interface_declaration -> { $interface_declaration.st }
	| enum_declaration -> { $enum_declaration.st }
	| annotation_declaration -> { $annotation_declaration.st }
   ;
// Identifiers
qualified_identifier:
	identifier ('.' identifier)*;
namespace_name
	: namespace_or_type_name ;

modifiers returns [List<string> modList]
@init {
   $modList = new List<string>();
}:
      (modifier { $modList.Add($modifier.thetext); })+ -> modifiers(mods={$modList});

modifier returns [string thetext]
: 
        (m='new' { $thetext = "new"; }
        | m='public' { $thetext = "public"; }
        | m='protected' { $thetext = "protected"; }
        | m='private' { $thetext = "private"; }
        | m='abstract' { $thetext = "abstract"; }
        | m='sealed' { $thetext = "sealed"; }
        | m='static' { $thetext = "static"; }
        | m='readonly' { $thetext = "readonly"; }
        | m='volatile' { $thetext = "volatile"; }
        | m='extern' { $thetext = "/* [UNSUPPORTED] 'extern' modifier not supported */"; } 
        | m='virtual' { $thetext = "virtual"; }
        | m='override' { $thetext = "override"; }
        | m=FINAL{ $thetext = "final"; })
        -> string(payload= { $thetext });

imports returns [List<string> importList]
@init {
    $importList = new List<string>();
}:
   (importns { $importList.Add($importns.thetext); })+ -> import_list(nss = { $importList });
importns returns [string thetext]:
   IMPORT PAYLOAD { $thetext = $PAYLOAD.text; } -> import_template(ns = { $PAYLOAD.text });
	
class_member_declaration returns [List<string> preComments]:
    ^(CONST attributes? modifiers? type { $preComments = CollectedComments; } constant_declarators)
    | ^(EVENT attributes? modifiers? { $preComments = CollectedComments; } event_declaration)
    | ^(METHOD attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list[$type_parameter_constraints_clauses.tpConstraints]? formal_parameter_list?
            { $preComments = CollectedComments; } method_body exception*)
      -> method(modifiers={$modifiers.st}, type={$type.st}, name={ $member_name.st }, typeparams = { $type_parameter_list.st }, params={ $formal_parameter_list.st }, exceptions = { $exception.st }, bodyIsSemi = { $method_body.isSemi }, body={ $method_body.st })
    | interface_declaration -> { $interface_declaration.st }
    | class_declaration[false] -> { $class_declaration.st }
    | ^(FIELD attributes? modifiers? type { $preComments = CollectedComments; } field_declaration)  -> field(modifiers={$modifiers.st}, type={$type.st}, field={$field_declaration.st}) 
    | ^(OPERATOR attributes? modifiers? type { $preComments = CollectedComments; } operator_declaration)
    | enum_declaration -> { $enum_declaration.st }
    | annotation_declaration -> { $annotation_declaration.st }
    | ^(CONSTRUCTOR attributes? modifiers? identifier  formal_parameter_list?  { $preComments = CollectedComments; } block exception*)
       -> constructor(modifiers={$modifiers.st}, name={ $identifier.st }, params={ $formal_parameter_list.st }, exceptions = { $exception.st}, bodyIsSemi = { $block.isSemi }, body={ $block.st })
    | ^(STATIC_CONSTRUCTOR attributes? modifiers? block)
       -> static_constructor(modifiers={$modifiers.st}, bodyIsSemi = { $block.isSemi }, body={ $block.st })
    ;

exception:
    EXCEPTION -> string(payload = { $EXCEPTION.text });

primary_expression returns [int precedence]
@init {
    $precedence = int.MaxValue;
    Dictionary<string,ReplacementDescriptor> templateMap = new Dictionary<string,ReplacementDescriptor>();
}: 
      ^(JAVAWRAPPER t=identifier 
                  (k=identifier v=wrapped 
                       {
                         if ($k.st.ToString() == "*")
                            templateMap["*"] = new ReplacementDescriptor($v.ppArgs); 
                         else
                            templateMap[$k.st.ToString()] = new ReplacementDescriptor($v.st != null ? $v.st.ToString() : "/* CS2J: <sorry, untranslated expression> */", $v.precedence); 
                       }
                  )*) 
             -> string(payload = { fillTemplate($t.st.ToString(), templateMap) })
    | ^(INDEX expression expression_list?) { $precedence = precedence[INDEX]; } -> index(func= { $expression.st }, funcparens = { comparePrecedence(precedence[INDEX], $expression.precedence) < 0 }, args = { $expression_list.st } )
    | ^(APPLY expression argument_list?) { $precedence = precedence[APPLY]; } -> application(func= { $expression.st }, funcparens = { comparePrecedence(precedence[APPLY], $expression.precedence) < 0 }, args = { $argument_list.st } )
    | ^((op=POSTINC|op=POSTDEC) expression) { $precedence = precedence[$op.token.Type]; } 
         -> op(pre={$expression.st}, op={ $op.token.Text }, preparens= { comparePrecedence($op.token, $expression.precedence) <= 0 })
    | primary_expression_start -> { $primary_expression_start.st }
    | ^(access_operator expression identifier generic_argument_list?) { $precedence = $access_operator.precedence; } 
       -> member_access(pre={ $expression.st }, op={ $access_operator.st }, access={ $identifier.st }, access_tyargs = { $generic_argument_list.st },
              preparen = { comparePrecedence($access_operator.precedence, $expression.precedence) < 0 })
//     | ^(access_operator expression SEP identifier) { $precedence = $access_operator.precedence; } 
//        -> op(pre={ $expression.st }, op={ $access_operator.st }, post={ $identifier.st },
//               preparen = { comparePrecedence($access_operator.precedence, $expression.precedence) < 0 })
//	('this'    brackets) => 'this'   brackets   primary_expression_part*
//	| ('base'   brackets) => 'this'   brackets   primary_expression_part*
//	| primary_expression_start   primary_expression_part*
    | ^(NEW type argument_list? object_or_collection_initializer?) { $precedence = precedence[NEW]; }-> construct(type = {$type.st}, args = {$argument_list.st}, inits = {$object_or_collection_initializer.st})
	| ^(NEW_DELEGATE type argument_list? class_body)  -> delegate(type = {$type.st}, args = {$argument_list.st}, body={$class_body.st})
	| ^(NEW_ANON_OBJECT anonymous_object_creation_expression)							// new {int X, string Y} 
	| sizeof_expression						// sizeof (struct)
	| checked_expression      -> { $checked_expression.st }      		// checked (...
	| unchecked_expression     -> { $unchecked_expression.st }     		// unchecked {...}
	| default_value_expression  -> { $default_value_expression.st }    		// default
	| anonymous_method_expression			// delegate (int foo) {}
	;
// primary_expression: 
// 	('this'    brackets) => 'this'   brackets   primary_expression_part*
// 	| ('base'   brackets) => 'this'   brackets   primary_expression_part*
// 	| primary_expression_start   pp+=primary_expression_part* -> primary_expression_start_parts(start={ $primary_expression_start.st }, follows={ $pp })
// 	| 'new' (   (object_creation_expression   ('.'|'->'|'[')) => 
// 					object_creation_expression   primary_expression_part+ 		// new Foo(arg, arg).Member
// 				// try the simple one first, this has no argS and no expressions
// 				// symantically could be object creation
// 				| (delegate_creation_expression) => delegate_creation_expression// new FooDelegate (MyFunction)
// 				| object_creation_expression
// 				| anonymous_object_creation_expression)							// new {int X, string Y} 
// 	| sizeof_expression						// sizeof (struct)
// 	| checked_expression            		// checked (...
// 	| unchecked_expression          		// unchecked {...}
// 	| default_value_expression      		// default
// 	| anonymous_method_expression			// delegate (int foo) {}
// 	;

primary_expression_start:
	predefined_type    -> { $predefined_type.st }        
	| (identifier    generic_argument_list) => identifier   generic_argument_list -> op(pre={ $identifier.st }, post={ $generic_argument_list.st})
	| i1=identifier -> { $i1.st } 
	| primary_expression_extalias -> unsupported(reason = {"external aliases are not yet supported"}, text= { $primary_expression_extalias.st } ) 
	| 'this' -> string(payload = { "this" }) 
	| SUPER-> string(payload = { "super" }) 
    // keving: needs fixing in javamaker - > type.class
	| ^('typeof'  unbound_type_name ) -> typeof(type= { $unbound_type_name.st })
	| ^('typeof'  type ) -> typeof(type= { $type.st })
	| literal -> { $literal.st }
	;

primary_expression_extalias:
	^('::' i1=identifier i2=identifier) -> op(pre={ $i1.st }, op = { "::" }, post={ $i2.st }) 
    ;


primary_expression_part:
	 access_identifier
	| brackets_or_arguments 
	| '++'
	| '--' ;
access_identifier:
	access_operator   type_or_generic ;
access_operator returns [int precedence]:
	(op=DOT  |  op='->') { $precedence = precedence[$op.token.Type]; } -> string(payload = { $op.token.Text }) ;
brackets_or_arguments:
	brackets | arguments ;
brackets:
	'['   expression_list?   ']' ;	
paren_expression:	
	'('   expression   ')' ;
arguments: 
	'('   argument_list?   ')' ;
argument_list returns [IList<StringTemplate> ppArgs]
@init {
   $ppArgs = new List<StringTemplate>();
}
: 
	^(ARGS (argument { $ppArgs.Add($argument.st); })+) -> list(items= {$ppArgs}, sep={", "});
// 4.0
argument:
	argument_name   argument_value
	| argument_value -> { $argument_value.st };
argument_name:
	argument_name_unsupported -> unsupported(reason={ "named parameters are not yet supported"}, text = { $argument_name_unsupported.st } );
argument_name_unsupported:
	identifier   ':' -> op(pre={$identifier.st}, op={":"});
argument_value  returns [int precedence]
@init {
    StringTemplate someText = null;
    $precedence = int.MaxValue;
}: 
	expression { $precedence = $expression.precedence; } -> { $expression.st }
	| ref_variable_reference 
	| 'out'   variable_reference 
        { someText = %op(); 
          %{someText}.op = "out"; 
          %{someText}.post = $variable_reference.st; 
          %{someText}.space = " ";
        } ->  unsupported(reason = {"out arguments are not yet supported"}, text = { someText } )
     ;
ref_variable_reference:
	'ref' 
		(('('   type   ')') =>   '('   type   ')'   (ref_variable_reference | variable_reference)   // SomeFunc(ref (int) ref foo)
																									// SomeFunc(ref (int) foo)
		| variable_reference);	// SomeFunc(ref foo)
// lvalue
variable_reference:
	expression -> { $expression.st };
rank_specifiers: 
	rs+=rank_specifier+ -> rank_specifiers(rs={$rs});        
rank_specifier: 
	'['  /* dim_separators? */   ']' -> string(payload={"[]"}) ;
// keving
// dim_separators: 
//	','+ ;

wrapped returns [int precedence, IList<StringTemplate> ppArgs]
@init {
    $precedence = int.MaxValue;
    $ppArgs = new List<StringTemplate>();
    Dictionary<string,ReplacementDescriptor> templateMap = new Dictionary<string,ReplacementDescriptor>();
}:
    ^(JAVAWRAPPEREXPRESSION expression) { $precedence = $expression.precedence; } -> { $expression.st } 
    | ^(JAVAWRAPPERARGUMENT argument_value) { $precedence = $argument_value.precedence; } -> { $argument_value.st } 
    | ^(JAVAWRAPPERARGUMENTLIST (argument_list  { $ppArgs = $argument_list.ppArgs; })?) -> { $argument_list.st } 
    | ^(JAVAWRAPPERTYPE type) -> { $type.st } 
    | ^(JAVAWRAPPER t=identifier 
         (k=identifier v=wrapped 
            {
               if ($k.st.ToString() == "*")
                  templateMap["*"] = new ReplacementDescriptor($v.ppArgs); 
               else
                  templateMap[$k.st.ToString()] = new ReplacementDescriptor($v.st != null ? $v.st.ToString() : "/* CS2J: <sorry, untranslated expression> */", $v.precedence); 
            }
          )*) -> string(payload = {fillTemplate($t.st.ToString(), templateMap)})
    ;

//delegate_creation_expression: 
	// 'new'   
//	type_name   '('   type_name   ')' ;
anonymous_object_creation_expression: 
	// 'new'
	anonymous_object_initializer ;
anonymous_object_initializer: 
	'{'   (member_declarator_list   ','?)?   '}';
member_declarator_list: 
	member_declarator  (',' member_declarator)* ; 
member_declarator: 
	qid   ('='   expression)? ;
primary_or_array_creation_expression returns [int precedence]:
	(array_creation_expression) => array_creation_expression { $precedence = $array_creation_expression.precedence; }  -> { $array_creation_expression.st } 
	| primary_expression { $precedence = $primary_expression.precedence; } -> { $primary_expression.st } 
	;
// new Type[2] { }
array_creation_expression returns [int precedence]:
	^(NEW_ARRAY   
		(type   ('['   expression_list?   ']'   rank_specifiers?   ai1=array_initializer?	 -> array_construct(type = { $type.st }, args = { $expression_list.st }, inits = { $ai1.st })  // new int[4]
				| ai2=array_initializer	-> 	array_construct_nobracks(type = { $type.st }, inits = { $ai2.st })
				)
		| rank_specifier  array_initializer	// var a = new[] { 1, 10, 100, 1000 }; // int[]
		    )
		) { $precedence = precedence[NEW]; };
array_initializer:
	'{'   variable_initializer_list?   ','?   '}' -> array_initializer(init = { $variable_initializer_list.st });
variable_initializer_list:
	vs+=variable_initializer (',' vs+=variable_initializer)* -> seplist(items = { $vs }, sep = {", "});
variable_initializer:
	expression	-> { $expression.st } | array_initializer -> { $array_initializer.st };
sizeof_expression:
	^('sizeof'  unmanaged_type );
checked_expression
@init {
    StringTemplate someText = null;
}: 
	^('checked' expression ) 
        { someText = %op(); 
          %{someText}.op = "checked"; 
          %{someText}.post = $expression.st; 
          %{someText}.space = " ";
        } ->  unsupported(reason = {"checked expressions are not supported"}, text = { someText } )
;
unchecked_expression
@init {
    StringTemplate someText = null;
}: 
	^('unchecked' expression ) 
        { someText = %op(); 
          %{someText}.op = "unchecked"; 
          %{someText}.post = $expression.st; 
          %{someText}.space = " ";
        } ->  unsupported(reason = {"unchecked expressions are not supported"}, text = { someText } )
;
default_value_expression
@init {
    StringTemplate someText = null;
}: 
	^('default' type   ) 
        { someText = %op(); 
          %{someText}.op = "default"; 
          %{someText}.post = $type.st; 
          %{someText}.space = " ";
        } ->  unsupported(reason = {"default expressions are not yet supported"}, text = { someText } )
;
anonymous_method_expression:
	^('delegate'   formal_parameter_list?   block);

///////////////////////////////////////////////////////
object_creation_expression: 
	// 'new'
	type   
		( '('   argument_list?   ')'   object_or_collection_initializer?  
		  | object_or_collection_initializer )
	;
object_or_collection_initializer: 
	'{'  (object_initializer 
		| collection_initializer) ;
collection_initializer: 
	element_initializer_list   ','?   '}' ;
element_initializer_list: 
	element_initializer  (',' element_initializer)* ;
element_initializer: 
	non_assignment_expression 
	| '{'   expression_list   '}' ;
// object-initializer eg's
//	Rectangle r = new Rectangle {
//		P1 = new Point { X = 0, Y = 1 },
//		P2 = new Point { X = 2, Y = 3 }
//	};
// TODO: comma should only follow a member_initializer_list
object_initializer: 
	member_initializer_list?   ','?   '}' ;
member_initializer_list: 
	member_initializer  (',' member_initializer)* ;
member_initializer: 
	identifier   '='   initializer_value ;
initializer_value: 
	expression 
	| object_or_collection_initializer ;

///////////////////////////////////////////////////////

// unbound type examples
//foo<bar<X<>>>
//bar::foo<>
//foo1::foo2.foo3<,,>
unbound_type_name:		// qualified_identifier v2
//	unbound_type_name_start unbound_type_name_part* ;
	unbound_type_name_start   
		(((generic_dimension_specifier   '.') => generic_dimension_specifier   unbound_type_name_part)
		| unbound_type_name_part)*   
			generic_dimension_specifier
	;

unbound_type_name_start:
	identifier ('::' identifier)?;
unbound_type_name_part:
	'.'   identifier;
generic_dimension_specifier: 
	'<'   commas?   '>' ;
commas: 
	','+ ; 

///////////////////////////////////////////////////////
//	Type Section
///////////////////////////////////////////////////////

type_name
@init {
    Dictionary<string,ReplacementDescriptor> templateMap = new Dictionary<string,ReplacementDescriptor>();
}: 
	namespace_or_type_name -> { $namespace_or_type_name.st }
   | ^(JAVAWRAPPER t=identifier 
         (k=identifier v=wrapped 
            {
               templateMap[$k.st.ToString()] = new ReplacementDescriptor($v.st != null ? $v.st.ToString() : "<sorry, untranslated expression>", $v.precedence); 
            }
      )*) -> string(payload = {fillTemplate($t.st.ToString(), templateMap)})
    ;
namespace_or_type_name:
	 t1=type_or_generic -> { $t1.st }
        // keving: external aliases not supported
    | ^('::' n2=type_name t2=type_or_generic) -> { $t2.st }
    | ^(op='.'  n3=type_name t3=type_or_generic)  -> op(pre={ $n3.st }, op = { "." }, post={ $t3.st });

//	 t1=type_or_generic   ('::' t2=type_or_generic)? ('.'   ts+=type_or_generic)* -> namespace_or_type(type1={$t1.st}, type2={$t2.st}, types={$ts});
type_or_generic returns [int precedence]
@init {
    $precedence = int.MaxValue;
}:
	(identifier   generic_argument_list) => gi=identifier   generic_argument_list -> op(pre={ $gi.st }, post={ $generic_argument_list.st })
	| i=identifier -> { $i.st };

qid:		// qualified_identifier v2
    ^(access_operator qd=qid type_or_generic) -> op(op={ $access_operator.st }, pre = { $qd.st}, post = { $type_or_generic.st })
	| qid_start  -> { $qid_start.st }
	;
qid_start:
	predefined_type -> { $predefined_type.st }
	| (identifier   generic_argument_list)	=> identifier   generic_argument_list -> op(pre={ $identifier.st }, post={ $generic_argument_list.st })
//	| 'this'
//	| 'base'
	| i1=identifier   ('::'   i2=identifier)?  -> identifier(id={ $i1.st }, id2={ $i2.st })
	| literal -> { $literal.st }
	;		// 0.ToString() is legal


qid_part:
	access_identifier ;

generic_argument_list:
	'<'   type_arguments   '>' -> generic_args(args={ $type_arguments.st });
type_arguments:
	ts+=type_argument (',' ts+=type_argument)* -> commalist(items = { $ts });

public type_argument:
    ('?' 'extends')=> '?' 'extends' type -> op(pre={"?"},op={" extends "},post={$type.st})
   | '?'  -> string(payload={"?"})
   | type -> { $type.st }
;
type
@init {
    StringTemplate nm = null;
    List<string> stars = new List<string>();
    string opt = null;
    Dictionary<string,ReplacementDescriptor> templateMap = new Dictionary<string,ReplacementDescriptor>();
}:
	  ^(TYPE (
            tp=predefined_type {nm=$tp.st;} 
            | tn=type_name {nm=$tn.st;} 
            | tv='void' { nm=%void();}
            )  rank_specifiers? ('*' { stars.Add("*");})* ('?' { opt = "?";} )?)  ->  type(name={ nm }, stars={ stars }, rs={ $rank_specifiers.st }, opt={ opt })
	;
non_nullable_type:
	type -> { $type.st } ;
	
non_array_type:
	type -> { $type.st } ;
array_type:
	type -> { $type.st } ;
unmanaged_type:
	type -> { $type.st } ;
pointer_type:
	type -> { $type.st } ;


///////////////////////////////////////////////////////
//	Statement Section
///////////////////////////////////////////////////////
block returns [bool isSemi]
@init {
    $isSemi = false;
}:
	';' { $isSemi = true; } -> string(payload = { "    ;" }) 
	| '{'   s+=statement*   '}' -> braceblock(statements = { $s });

///////////////////////////////////////////////////////
//	Expression Section
///////////////////////////////////////////////////////	
expression returns [int precedence]: 
	(unary_expression   assignment_operator) => assignment { $precedence = $assignment.precedence; } -> { $assignment.st }
	| non_assignment_expression { $precedence = $non_assignment_expression.precedence; } -> { $non_assignment_expression.st }
	;
expression_list:
	e+=expression  (','   e+=expression)* -> list(items= { $e }, sep = {", "});
assignment returns [int precedence]:
	unary_expression   assignment_operator   expression { $precedence = $assignment_operator.precedence; }
                                                         -> assign(lhs={ $unary_expression.st }, assign = { $assignment_operator.st }, rhs = { $expression.st }, 
                                                                    lhsparen={ comparePrecedence($assignment_operator.precedence, $unary_expression.precedence) <= 0 },
                                                                     rhsparen={ comparePrecedence($assignment_operator.precedence, $expression.precedence) < 0});
unary_expression returns [int precedence]
@init {
    // By default parens not needed
    $precedence = int.MaxValue;
}: 
	//('(' arguments ')' ('[' | '.' | '(')) => primary_or_array_creation_expression
//	^(CAST_EXPR type expression) 
	^(CAST_EXPR type u0=expression)  { $precedence = precedence[CAST_EXPR]; } -> cast_expr(type= { $type.st}, exp = { $u0.st})
	| primary_or_array_creation_expression { $precedence = $primary_or_array_creation_expression.precedence; } -> { $primary_or_array_creation_expression.st }
	| ^((op=MONOPLUS | op=MONOMINUS | op=MONONOT | op=MONOTWIDDLE | op=PREINC | op=PREDEC)  u1=unary_expression) { $precedence = precedence[$op.token.Type]; }
          -> op(postparen={ comparePrecedence($op.token, $u1.precedence) <= 0 }, op={ $op.token.Text }, post={$u1.st})
	| ^((op=MONOSTAR|op=ADDRESSOF) u1=unary_expression) 
        { 
            StringTemplate opText = %op();
            %{opText}.post = $u1.st;
            %{opText}.op = $op.token.Text;
            $st = %unsupported();
            %{$st}.reason = "the " + ($op.token.Type == MONOSTAR ? "pointer indirection" : "address of") + " operator is not supported";
            %{$st}.text = opText;
        }
      // PARENS is not strictly necessary because we insert parens where necessary. However
      // we maintain parens inserted by original programmer since, presumably, they 
      // improve understandability
	| ^(PARENS expression) { $precedence = Cfg.TranslatorKeepParens ? int.MaxValue : $expression.precedence; } 
                           -> { Cfg.TranslatorKeepParens}? parens(e={$expression.st}) 
                           -> {$expression.st} 
    ;

// 	(cast_expression) => cast_expression 
// 	| primary_or_array_creation_expression -> { $primary_or_array_creation_expression.st }
// 	| '+'   u1=unary_expression -> template(e={$u1.st}) "+<e>"
// 	| '-'   u2=unary_expression  -> template(e={$u2.st}) "-<e>"
// 	| '!'   u3=unary_expression  -> template(e={$u3.st}) "!<e>"
// 	| '~'   u4=unary_expression  -> template(e={$u4.st}) "~<e>"
// 	| pre_increment_expression 
// 	| pre_decrement_expression 
// 	| pointer_indirection_expression
// 	| addressof_expression 
// 	;
// cast_expression:
// 	^(CAST_EXPR  type unary_expression ) -> cast_expr(type= { $type.st}, exp = { $unary_expression.st});
 assignment_operator returns [int precedence]: 
   (op='=' | op='+=' | op='-=' | op='*=' | op='/=' | op='%=' | op='&=' | op='|=' | op='^=' | op='<<=' | op=RIGHT_SHIFT_ASSIGN) { $precedence = precedence[$op.token.Type]; } 
      -> string(payload = { $op.token.Text });
// pre_increment_expression: 
// 	'++'   unary_expression ;
// pre_decrement_expression: 
// 	'--'   unary_expression ;
// pointer_indirection_expression:
// 	'*'   unary_expression ;
// addressof_expression:
// 	'&'   unary_expression ;

non_assignment_expression returns [int precedence]
@init {
    // By default parens not needed
    $precedence = int.MaxValue;
}: 
	//'non ASSIGNment'
	(anonymous_function_signature?  '=>')	=> lambda_expression { $precedence = precedence[LAMBDA]; } -> { $lambda_expression.st; }
	| (query_expression) => query_expression 
	| ^(cop=COND_EXPR ce1=non_assignment_expression ce2=expression ce3=expression) { $precedence = precedence[$cop.token.Type]; } 
          -> cond( condexp = { $ce1.st }, thenexp = { $ce2.st }, elseexp = { $ce3.st },
                    condparens = { comparePrecedence($cop.token, $ce1.precedence) <= 0 }, 
                    thenparens = { comparePrecedence($cop.token, $ce2.precedence) <= 0 }, 
                    elseparens = { comparePrecedence($cop.token, $ce3.precedence) <= 0 }) 
    | ^('??' non_assignment_expression non_assignment_expression)
    // All these operators have left to right associativity
    | ^((op='=='|op='!='|op='||'|op='&&'|op='|'|op='^'|op='&'|op='>'|op='<'|op='>='|op='<='|op='<<'|op=RIGHT_SHIFT|op='+'|op='-'|op='*'|op='/'|op='%') 
        e1=non_assignment_expression e2=non_assignment_expression) { $precedence = precedence[$op.token.Type]; }
         -> op(pre={ $e1.st }, op = { $op.token.Text }, post = { $e2.st }, space = { " " },
                preparen={ comparePrecedence($op.token, $e1.precedence) < 0 },
                postparen={ comparePrecedence($op.token, $e2.precedence) <= 0})
    | ^(iop=INSTANCEOF ie=non_assignment_expression non_nullable_type) { $precedence = precedence[$iop.token.Type]; } 
          -> op(pre = { $ie.st }, op = { "instanceof" }, space = { " " }, post = { $non_nullable_type.st },
                  preparen={ comparePrecedence($iop.token, $ie.precedence) < 0 })
    | unary_expression { $precedence = $unary_expression.precedence; }-> { $unary_expression.st }
	;

///////////////////////////////////////////////////////
//	lambda Section
///////////////////////////////////////////////////////
lambda_expression:
	anonymous_function_signature?   '=>'   block 
        { 
            StringTemplate lambdaText = %lambda();
            %{lambdaText}.args = $anonymous_function_signature.st;
            %{lambdaText}.body = $block.st;
            $st = %unsupported();
            %{$st}.reason = "to translate lambda expressions we need an explicit delegate type, try adding a cast";
            %{$st}.text = lambdaText;
        }
   ;
anonymous_function_signature:
	^(PARAMS fps+=formal_parameter+) -> list(items= {$fps}, sep={", "})
	| ^(PARAMS_TYPELESS ids+=identifier+) -> list(items= {$ids}, sep={", "})
	;

///////////////////////////////////////////////////////
//	LINQ Section
///////////////////////////////////////////////////////
query_expression:
	from_clause   query_body ;
query_body:
	// match 'into' to closest query_body
	query_body_clauses?   select_or_group_clause   (('into') => query_continuation)? ;
query_continuation:
	'into'   identifier   query_body;
query_body_clauses:
	query_body_clause+ ;
query_body_clause:
	from_clause
	| let_clause
	| where_clause
	| join_clause
	| orderby_clause;
from_clause:
	'from'   type?   identifier   'in'   expression ;
join_clause:
	'join'   type?   identifier   'in'   expression   'on'   expression   'equals'   expression ('into' identifier)? ;
let_clause:
	'let'   identifier   '='   expression;
orderby_clause:
	'orderby'   ordering_list ;
ordering_list:
	ordering   (','   ordering)* ;
ordering:
	expression    ordering_direction?
	;
ordering_direction:
	'ascending'
	| 'descending' ;
select_or_group_clause:
	select_clause
	| group_clause ;
select_clause:
	'select'   expression ;
group_clause:
	'group'   expression   'by'   expression ;
where_clause:
	'where'   boolean_expression ;
boolean_expression:
	expression -> { $expression.st };

///////////////////////////////////////////////////////
// B.2.13 Attributes
///////////////////////////////////////////////////////
global_attributes: 
	global_attribute+ ;
global_attribute: 
	^(GLOBAL_ATTRIBUTE global_attribute_target_specifier   attribute_list) ;
global_attribute_target_specifier: 
	global_attribute_target   ':' ;
global_attribute_target: 
	'assembly' | 'module' ;
attributes: 
	attribute_sections -> { $attribute_sections.st } ;
attribute_sections: 
	ass+=attribute_section+ ;
attribute_section: 
	^(ATTRIBUTE attribute_target_specifier?   attribute_list) ;
attribute_target_specifier: 
	attribute_target   ':' ;
attribute_target: 
	'field' | 'event' | 'method' | 'param' | 'property' | 'return' | 'type' ;
attribute_list: 
	attribute (',' attribute)* ; 
attribute: 
	type_name   attribute_arguments? ;
// TODO:  allows a mix of named/positional arguments in any order
attribute_arguments: 
	'('   (')'										// empty
		   | (positional_argument   ((','   identifier   '=') => named_argument
		   							 |','	positional_argument)*
			  )	')'
			) ;
positional_argument_list: 
	^(ARGS positional_argument+) ;
positional_argument: 
	attribute_argument_expression ;
named_argument_list: 
	^(ARGS named_argument+) ;
named_argument: 
	identifier   '='   attribute_argument_expression ;
attribute_argument_expression: 
	expression ;

///////////////////////////////////////////////////////
//	Class Section
///////////////////////////////////////////////////////

class_declaration[bool topLevel]
scope TypeContext;
@init {
    List<string> preComments = null;
    String name = "";
    bool isPartial = false;
    $TypeContext::partialTypes = new Dictionary<string,ClassDescriptorSerialized>();
}:
   ^(c=CLASS ('partial' { isPartial = true; })? PAYLOAD?
            attributes? modifiers? identifier { name = $identifier.st.ToString(); } type_parameter_constraints_clauses? type_parameter_list[$type_parameter_constraints_clauses.tpConstraints]?
         class_extends? class_implements?  { preComments = CollectedComments; preComments.Add($PAYLOAD.text); } class_body )
      {
         
         if (isPartial) {
            // build a serialized descriptor and merge it
            ClassDescriptorSerialized part = new ClassDescriptorSerialized(name);

            if (preComments != null) { 
               foreach (String comment in preComments) {
                  part.Comments += comment ;
               }
            }
            // Union all attributes
            part.Atts += mkString($attributes.st);
            // Merge modifiers
            if ($modifiers.modList != null && $modifiers.modList.Count > 0) {
               foreach (string m in $modifiers.modList) {
                  part.Mods.Add(m);
               }
            }
            part.TypeParameterList = mkString($type_parameter_list.st);

            if ($class_extends.extendList != null && $class_extends.extendList.Count > 0) {
               foreach (string m in $class_extends.extendList) {
                  part.ClassExtends.Add(m);
               }
            }
            
            if ($class_implements.implementList != null && $class_implements.implementList.Count > 0) {
               foreach (string m in $class_implements.implementList) {
                  part.ClassImplements.Add(m);
               }
            }

            part.ClassBody += mkString($class_body.st);
            part.PartialTypes = $TypeContext::partialTypes;

            // Place this in our parent's scope
            Dictionary<string,ClassDescriptorSerialized> parentPartialTypes = ((TypeContext_scope)$TypeContext.ToArray()[1]).partialTypes;
            if (!parentPartialTypes.ContainsKey(name)) {
               parentPartialTypes[name] = part;
            }
            else {
               mergeParts(parentPartialTypes[name], part);
            }
         }
      }
    -> {isPartial}?
    -> class(modifiers = { $modifiers.st }, name={ $identifier.st }, typeparams= {$type_parameter_list.st}, comments = { preComments },
            extends = { $class_extends.st }, imps = { $class_implements.st }, body={$class_body.st}, partial_types = { emitParts($TypeContext::partialTypes) }) ;

type_parameter_list [Dictionary<string,StringTemplate> tpConstraints]:
    (attributes? t+=type_parameter[tpConstraints])+ -> type_parameter_list(items={ $t });

type_parameter [Dictionary<string,StringTemplate> tpConstraints]
@init {
    StringTemplate mySt = null; 
}:
    identifier {if (tpConstraints == null || !tpConstraints.TryGetValue($identifier.text, out mySt)) {mySt = $identifier.st;}; } -> { mySt } ;

class_extends returns [List<String> extendList]
@init {
    $extendList = new List<String>();
}:
      (class_extend { $extendList.Add($class_extend.extend); })+ -> extends(types = { $extendList }) ;
class_extend returns [string extend]:
	^(EXTENDS ts=type { $extend = $ts.st.ToString(); }) -> { $ts.st } ;
class_implements returns [List<String> implementList]
@init {
    $implementList = new List<String>();
}:
	(class_implement {$implementList.Add($class_implement.implement); })+ -> imps(types = { $implementList }) ;
class_implement returns [string implement]:
	^(IMPLEMENTS ts=type) { $implement = $ts.st.ToString(); } -> { $ts.st };
	
interface_type_list:
	ts+=type (','   ts+=type)* -> commalist(items={ $ts });

class_body:
	'{'   cs+=class_member_declaration_aux*   '}' -> class_body(entries={$cs}) ;
class_member_declaration_aux:
    member=class_member_declaration -> class_member(comments={ $member.preComments }, member={ $member.st }) ;


///////////////////////////////////////////////////////
constant_declaration:
	'const'   type   constant_declarators   ';' ;
constant_declarators:
	constant_declarator (',' constant_declarator)* ;
constant_declarator:
	identifier   ('='   constant_expression)? ;
constant_expression:
	expression -> { $expression.st };

///////////////////////////////////////////////////////
field_declaration:
	variable_declarators	-> { $variable_declarators.st };
variable_declarators:
	vs+=variable_declarator (','   vs+=variable_declarator)* -> variable_declarators(varinits = {$vs});
variable_declarator:
	type_name ('='   variable_initializer)? -> variable_declarator(typename = { $type_name.st }, init = { $variable_initializer.st}) ;		// eg. event EventHandler IInterface.VariableName = Foo;

///////////////////////////////////////////////////////

method_body returns [bool isSemi]:
	block { $isSemi = $block.isSemi; } -> { $block.st };

member_name
@init {
    StringTemplate last_t = null;
    ArrayList pre_ts = new ArrayList();
}
:
    (type_or_generic '.') => t1=type_or_generic { last_t = $t1.st; } (op='.' tn=type_or_generic { pre_ts.Add(last_t); last_t = $tn.st; })* 
        { 
            StringTemplate interfaceText = %dotlist();
            %{interfaceText}.items = pre_ts;
            StringTemplate opText = %op();
            %{opText}.pre = interfaceText;
            %{opText}.op = $op.token.Text;
            StringTemplate unsupportedText = %unsupported();
            %{unsupportedText}.reason = "explicit interface implementation is not supported";
            %{unsupportedText}.text = opText;
            $st = %op();
            %{$st}.pre = unsupportedText;
            %{$st}.post = last_t;
            %{$st}.op = " ";
        }
    | type_or_generic -> { $type_or_generic.st }
    ;
    // keving: missing interface_type.identifier
//	identifier -> { $identifier.st };		// IInterface<int>.Method logic added.
//member_name:
//	qid -> { $qid.st };		// IInterface<int>.Method logic added.

///////////////////////////////////////////////////////
event_declaration:
	type member_name   '{'   event_accessor_declarations   '}'
		;
event_modifiers:
	modifier+ ;
event_accessor_declarations:
	attributes?   ((add_accessor_declaration   attributes?   remove_accessor_declaration)
	              | (remove_accessor_declaration   attributes?   add_accessor_declaration)) ;
add_accessor_declaration:
	'add'   block ;
remove_accessor_declaration:
	'remove'   block ;


///////////////////////////////////////////////////////
//	annotation declaration
///////////////////////////////////////////////////////
annotation_declaration
@init {
    List<string> preComments = null;
}:
	^(ANNOTATION attributes? modifiers? identifier  { preComments = CollectedComments; } class_body? )
    -> annotation(comments = { preComments}, modifiers = { $modifiers.st }, name={$identifier.text}, body={$class_body.st}) ;

///////////////////////////////////////////////////////
//	enum declaration
///////////////////////////////////////////////////////
enum_declaration
@init {
    List<string> preComments = null;
}:
	^(ENUM { preComments = CollectedComments; } attributes? modifiers? identifier   enum_base?   enum_body )
    -> enum(comments = { preComments}, modifiers = { $modifiers.st }, name={$identifier.text}, body={$enum_body.st}) ;
enum_base:
	type ;
enum_body:
	^(ENUM_BODY es+=enum_member_declaration*) -> enum_body(values={$es});
enum_member_declaration:
	attributes?   identifier -> enum_member(comments = { CollectedComments }, value={ $identifier.st });
//enum_modifiers:
//	enum_modifier+ ;
//enum_modifier:
//	'new' | 'public' | 'protected' | 'internal' | 'private' ;
integral_type: 
	'sbyte' | 'byte' | 'short' | 'ushort' | 'int' | 'uint' | 'long' | 'ulong' | 'char' ;

// 4.0
variant_generic_parameter_list [Dictionary<string,StringTemplate> tpConstraints]:
	(ps+=variant_generic_parameter[$tpConstraints])+ -> type_parameter_list(items={$ps});
variant_generic_parameter [Dictionary<string,StringTemplate> tpConstraints]:
    attributes?   variance_annotation?  t=type_parameter[$tpConstraints] -> { $t.st };
variance_annotation:
	IN -> string(payload={ "in" }) | OUT -> string(payload={ "out" }) ;

// tpConstraints is a map from type variable name to a string expressing the extends constraints
type_parameter_constraints_clauses returns [Dictionary<string,StringTemplate> tpConstraints]
@init {
    $tpConstraints = new Dictionary<string,StringTemplate>();
}
:
	ts+=type_parameter_constraints_clause[$tpConstraints]+ -> ;
type_parameter_constraints_clause [Dictionary<string,StringTemplate> tpConstraints]
@after{
    tpConstraints[$t.text] = $type_parameter_constraints_clause.st;
}:
    ^(TYPE_PARAM_CONSTRAINT t=type_variable_name ts+=type_name+) -> type_param_constraint(param= { $type_variable_name.st }, constraints = { $ts }) ;
type_variable_name: 
	identifier -> { $identifier.st } ;
// keving: stripped
//constructor_constraint:
//	'new'   '('   ')' ;
return_type:
	type -> { $type.st } ;
formal_parameter_list:
    ^(PARAMS fps+=formal_parameter+) -> list(items= {$fps}, sep={", "});
formal_parameter:
	attributes?   (fixed_parameter -> { $fixed_parameter.st }| parameter_array -> { $parameter_array.st }) 
	| '__arglist';	// __arglist is undocumented, see google
//fixed_parameters:
//	fps+=fixed_parameter   (','   fps+=fixed_parameter)* -> { $fps };
// 4.0
fixed_parameter:
	parameter_modifier?   type   identifier   default_argument? -> fixed_parameter(mod={ $parameter_modifier.st }, type = { $type.st }, name = { $identifier.st }, default = { $default_argument.st });
// 4.0
default_argument:
	'=' expression -> { $expression.st };
parameter_modifier:
	(m='ref' | m='out' | m='this') -> inline_comment(payload={ $m.text }, explanation={ "parameter modifiers are not yet supported" }) ;
parameter_array:
	^('params'   type   identifier) -> varargs(type={ $type.st }, name = { $identifier.st }) ;

///////////////////////////////////////////////////////
interface_declaration
@init {
    List<string> preComments = null;
    String name = "";
    bool isPartial = false;
}:
   ^(c=INTERFACE ('partial' { isPartial = true; })? attributes? modifiers?
            identifier { name = $identifier.st.ToString(); } type_parameter_constraints_clauses?  variant_generic_parameter_list[$type_parameter_constraints_clauses.tpConstraints]?
         class_extends?   { preComments = CollectedComments; } interface_body )
      {
         
         if (isPartial) {
            // build a serialized descriptor and merge it
            ClassDescriptorSerialized part = new ClassDescriptorSerialized(name);

            if (preComments != null) { 
               foreach (String comment in preComments) {
                  part.Comments += comment ;
               }
            }
            part.Type = "interface";
            // Union all attributes
            part.Atts += mkString($attributes.st);
            // Merge modifiers
            if ($modifiers.modList != null && $modifiers.modList.Count > 0) {
               foreach (string m in $modifiers.modList) {
                  part.Mods.Add(m);
               }
            }
            part.TypeParameterList = mkString($variant_generic_parameter_list.st);

            if ($class_extends.extendList != null && $class_extends.extendList.Count > 0) {
               foreach (string m in $class_extends.extendList) {
                  part.ClassExtends.Add(m);
               }
            }

            part.ClassBody += mkString($interface_body.st);

            // Place this in our parent's scope (We don't declare a TypeContext scope because interfaces don't have nested types)
            if (!$TypeContext::partialTypes.ContainsKey(name)) {
               $TypeContext::partialTypes[name] = part;
            }
            else {
               mergeParts($TypeContext::partialTypes[name], part);
            }
         }
      }
    -> {isPartial}?
    -> class(type={ "interface" }, modifiers = { $modifiers.st }, name={ $identifier.st }, typeparams={$variant_generic_parameter_list.st} ,comments = { preComments },
            imps = { $class_extends.st }, body = { $interface_body.st }) ;
//interface_base: 
//   	':' interface_type_list ;
interface_body:
	'{'   ms+=interface_member_declaration_aux*   '}' -> class_body(entries = { $ms });
interface_member_declaration_aux:
	member=interface_member_declaration -> class_member(comments = { $member.preComments }, member = { $member.st });

interface_member_declaration returns [List<string> preComments]:
    ^(EVENT attributes? modifiers? event_declaration)
    | ^(METHOD attributes? modifiers? type identifier type_parameter_constraints_clauses? type_parameter_list[$type_parameter_constraints_clauses.tpConstraints]? formal_parameter_list? exception*)
         { $preComments = CollectedComments; }
      -> method(modifiers={$modifiers.st}, type={$type.st}, name={ $identifier.st }, typeparams = { $type_parameter_list.st }, params={ $formal_parameter_list.st }, exceptions= { $exception.st }, bodyIsSemi = { true })
		;

///////////////////////////////////////////////////////
operator_declaration:
	operator_declarator   operator_body ;
operator_declarator:
	'operator' 
	(('+' | '-')   '('   type   identifier   (binary_operator_declarator | unary_operator_declarator)
		| overloadable_unary_operator   '('   type identifier   unary_operator_declarator
		| overloadable_binary_operator   '('   type identifier   binary_operator_declarator) ;
unary_operator_declarator:
	   ')' ;
overloadable_unary_operator:
	/*'+' |  '-' | */ '!' |  '~' |  '++' |  '--' |  'true' |  'false' ;
binary_operator_declarator:
	','   type   identifier   ')' ;
// >> check needed
overloadable_binary_operator:
	/*'+' | '-' | */ '*' | '/' | '%' | '&' | '|' | '^' | '<<' | '>' '>' | '==' | '!=' | '>' | '<' | '>=' | '<=' ; 

conversion_operator_declaration:
	conversion_operator_declarator   operator_body ;
conversion_operator_declarator:
	('implicit' | 'explicit')  'operator'   type   '('   type   identifier   ')' ;
operator_body:
	block ;

///////////////////////////////////////////////////////
invocation_expression:
	invocation_start   (((arguments   ('['|'.'|'->')) => arguments   invocation_part)
						| invocation_part)*   arguments ;
invocation_start:
	predefined_type 
	| (identifier    generic_argument_list)	=> identifier   generic_argument_list
	| 'this' 
	| 'base'
	| identifier   ('::'   identifier)?
	| ^('typeof'  (unbound_type_name | type ) )             // typeof(Foo).Name
	;
invocation_part:
	 access_identifier
	| brackets ;

///////////////////////////////////////////////////////

// keving: split statement into two parts, there seems to be a problem with the state
// machine if we combine statement and statement_plus.
statement:
	(declaration_statement) => declaration_statement -> statement(statement = { $declaration_statement.st })
	| statement_plus -> statement(statement = { $statement_plus.st })
	;
statement_plus:
	labeled_statement -> statement(statement = { $labeled_statement.st })
	| embedded_statement  -> statement(statement = { $embedded_statement.st })
	;
embedded_statement returns [bool isSemi, bool isIf, bool indent]
@init {
    StringTemplate someText = null;
    $isSemi = false;
    $isIf = false;
    $indent = true;
    List<string> preComments = null;
}:
	block { $isSemi = $block.isSemi; $indent = false; } -> { $block.st }
	| ^(IF boolean_expression { preComments = CollectedComments; } SEP  t=embedded_statement e=else_statement?) { $isIf = true; }
        -> if_template(comments = { preComments }, cond= { $boolean_expression.st }, 
              then = { $t.st }, thenindent = { $t.indent }, 
              else = { $e.st }, elseisif = { $e.isIf }, elseindent = { $e.indent})
    | ^('switch' expression  { preComments = CollectedComments; } s+=switch_section*) -> switch(comments = { preComments }, scrutinee = { $expression.st }, sections = { $s }) 
	| iteration_statement -> { $iteration_statement.st }	// while, do, for, foreach
	| jump_statement	-> { $jump_statement.st }	// break, continue, goto, return, throw
	| ^('try'  { preComments = CollectedComments; } b=block catch_clauses? finally_clause?) 
        -> try(comments = { preComments }, block = {$b.st}, blockindent = { $b.isSemi }, 
               catches = { $catch_clauses.st }, fin = { $finally_clause.st } )
	| checked_statement -> { $checked_statement.st }
	| unchecked_statement -> { $unchecked_statement.st }
    | synchronized_statement -> { $synchronized_statement.st }
	| yield_statement -> { $yield_statement.st } 
    | ^('unsafe'  { preComments = CollectedComments; }   block { someText = %op(); %{someText}.op="unsafe"; %{someText}.post = $block.st; })
      -> unsupported(comments = { preComments }, reason = {"unsafe blocks are not supported"}, text = { someText } )
	| fixed_statement
	| expression_statement  { preComments = CollectedComments; }	
         -> op(comments = { preComments }, pre={ $expression_statement.st }, op={ ($expression_statement.st.ToString() == "" ? "" : ";") })  // make an expression a statement, if non-empty (e.g. unimplemented partial methods) need to terminate with semi
	;
fixed_statement:
	'fixed'   '('   pointer_type fixed_pointer_declarators   ')'   embedded_statement ;
fixed_pointer_declarators:
	fixed_pointer_declarator   (','   fixed_pointer_declarator)* ;
fixed_pointer_declarator:
	identifier   '='   fixed_pointer_initializer ;
fixed_pointer_initializer:
	//'&'   variable_reference   // unary_expression covers this
	expression;
labeled_statement:
	identifier ':' statement -> op(pre={ $identifier.st }, op= { ":" }, post = { $statement.st});
declaration_statement
@init {
    List<string> preComments = null;
}:
	(local_variable_declaration { preComments = CollectedComments; } -> op(comments = { preComments }, pre = { $local_variable_declaration.st }, op = { ";" })
	| local_constant_declaration { preComments = CollectedComments; } -> op(comments = { preComments }, pre = { $local_constant_declaration.st }, op = { ";" }) ) ';' ;
local_variable_declaration:
	local_variable_type   local_variable_declarators -> local_variable_declaration(type={ $local_variable_type.st }, decs = { $local_variable_declarators.st } );
local_variable_type:
	TYPE_VAR -> unsupported(reason = {"'var' as type is unsupported"}, text = { "var" } )
	| TYPE_DYNAMIC -> unsupported(reason = {"'dynamic' as type is unsupported"}, text = { "dynamic" } )
	| type  -> { $type.st } ;
local_variable_declarators:
	vs+=local_variable_declarator (',' vs+=local_variable_declarator)* -> list(items={$vs}, sep={", "});
local_variable_declarator:
	identifier ('='   local_variable_initializer)? -> local_variable_declarator(name= { $identifier.st }, init = { $local_variable_initializer.st }); 
local_variable_initializer:
	expression -> { $expression.st }
	| array_initializer 
	| stackalloc_initializer;
stackalloc_initializer:
	 stackalloc_initializer_unsupported -> unsupported(reason={"'stackalloc' is unsupported"}, text={ $stackalloc_initializer_unsupported.st });
stackalloc_initializer_unsupported:
	'stackalloc'   unmanaged_type   '['   expression   ']' -> stackalloc(type={$unmanaged_type.st}, exp = { $expression.st });
local_constant_declaration:
	'const'   type   constant_declarators ;
expression_statement:
	expression   ';'  -> { $expression.st };

// TODO: should be assignment, call, increment, decrement, and new object expressions
statement_expression:
	expression -> { $expression.st }
	;
if_statement:
	// else goes with closest if
	
	;
else_statement returns [bool isSemi, bool isIf, bool indent]:
	'else'   s=embedded_statement	{ $isSemi = $s.isSemi; $isIf = $s.isIf; $indent = $s.indent; } -> { $embedded_statement.st } ;
switch_section:
    ^(SWITCH_SECTION lab+=switch_label+ stat+=statement+) -> switch_section(labels = { $lab }, statements = { $stat });
switch_label:
	^('case'   constant_expression) -> case(what = { $constant_expression.st })
	| 'default' -> default_template() ;
iteration_statement:
	^('while' boolean_expression  SEP embedded_statement) 
          -> while(cond = { $boolean_expression.st }, block = { $embedded_statement.st }, blockindent = { $embedded_statement.indent })
	| do_statement -> { $do_statement.st }
	| ^('for' for_initializer? SEP expression? SEP for_iterator? SEP embedded_statement)
         -> for(init = { $for_initializer.st }, cond = { $expression.st }, iter = { $for_iterator.st },
                      block = { $embedded_statement.st }, blockindent = { $embedded_statement.indent })
	| ^('foreach' local_variable_type   identifier  expression SEP  embedded_statement) 
          -> foreach(type = { $local_variable_type.st }, loopid = { $identifier.st }, fromexp = { $expression.st },
                      block = { $embedded_statement.st }, blockindent = { $embedded_statement.indent });
do_statement:
	'do'   embedded_statement   'while'   '('   boolean_expression   ')'   ';' -> do(cond = { $boolean_expression.st }, block = { $embedded_statement.st }, blockindent = { $embedded_statement.indent });
for_initializer:
	(local_variable_declaration) => local_variable_declaration -> { $local_variable_declaration.st }
	| statement_expression_list -> { $statement_expression_list.st }
	;
for_iterator:
	statement_expression_list -> { $statement_expression_list.st };
statement_expression_list:
	s+=statement_expression (',' s+=statement_expression)* -> list(items = { $s }, sep = { ", " });
jump_statement:
	'break'   ';'  -> string(payload={"break;"})
	| 'continue'   ';' -> string(payload={"continue;"})
	| goto_statement-> { $goto_statement.st }
	| ^('return'   expression?) -> return(exp = { $expression.st })
	| ^('throw'   expression?) -> throw(exp = { $expression.st });
goto_statement:
	'goto'   ( identifier -> op(op={"goto"}, post={$identifier.st}, space={" "})
			 | 'case'   constant_expression  -> op(op={"goto case"}, post={$constant_expression.st})
			 | 'default' -> string(payload={"goto default"}) )   ';' ;
catch_clauses:
    c+=catch_clause+ -> seplist(items={ $c }, sep = { "\n" }) ;
catch_clause:
	^('catch' type identifier block) -> catch_template(type = { $type.st }, id = { $identifier.st }, block = {$block.st}, blockindent = { $block.isSemi } );
finally_clause:
	^('finally'   block) -> fin(block = {$block.st}, blockindent = { $block.isSemi });

synchronized_statement: 
	^(SYNCHRONIZED expression embedded_statement) -> synchstat(exp={ $expression.st }, stat = { $embedded_statement.st }, indent = { $embedded_statement.indent });

checked_statement
@init {
    StringTemplate someText = null;
}:
	'checked'   block 
        { someText = %keyword_block(); 
          %{someText}.keyword = "checked"; 
          %{someText}.block = $block.st;
          %{someText}.indent = $block.isSemi; } ->  unsupported(reason = {"checked statements are not supported"}, text = { someText } )
;
unchecked_statement
@init {
    StringTemplate someText = null;
}:
	^(UNCHECKED   block) 
        { someText = %keyword_block(); 
          %{someText}.keyword = "unchecked"; 
          %{someText}.block = $block.st;
          %{someText}.indent = $block.isSemi; } ->  unsupported(reason = {"checked statements are not supported"}, text = { someText } )
;
yield_statement
@init {
    StringTemplate someText = null;
    someText = %yield(); 
}:
    ^(YIELD_RETURN expression { %{someText}.exp = $expression.st; })
    | YIELD_BREAK {%{someText}.exp = "break"; } 
         ->  unsupported(reason = {"yield statements are not supported"}, text = { someText } )
;

///////////////////////////////////////////////////////
//	Lexar Section
///////////////////////////////////////////////////////

predefined_type:
	  (t='bool' | t='byte'   | t='char'   | t='decimal' | t='double' | t='float'  | t='int'    | t='long'   | t='object' | t='sbyte'  
	| t='short'  | t='string' | t='uint'   | t='ulong'  | t='ushort') { collectComments($t.TokenStartIndex); } ->  string(payload={$t.text});

identifier:
 	i=IDENTIFIER { collectComments($i.TokenStartIndex); } -> string(payload= { $IDENTIFIER.text }) | also_keyword -> { $also_keyword.st };

keyword:
	'abstract' | 'as' | 'base' | 'bool' | 'break' | 'byte' | 'case' |  'catch' | 'char' | 'checked' | 'class' | 'const' | 'continue' | 'decimal' | 'default' | 'delegate' | 'do' |	'double' | 'else' |	 'enum'  | 'event' | 'explicit' | 'extern' | 'false' | 'finally' | 'fixed' | 'float' | 'for' | 'foreach' | 'goto' | 'if' | 'implicit' | 'in' | 'int' | 'interface' | 'internal' | 'is' | 'lock' | 'long' | 'namespace' | 'new' | 'null' | 'object' | 'operator' | 'out' | 'override' | 'params' | 'private' | 'protected' | 'public' | 'readonly' | 'ref' | 'return' | 'sbyte' | 'sealed' | 'short' | 'sizeof' | 'stackalloc' | 'static' | 'string' | 'struct' | 'switch' | 'this' | 'throw' | 'true' | 'try' | 'typeof' | 'uint' | 'ulong' | 'unchecked' | 'unsafe' | 'ushort' | 'using' | 'virtual' | 'void' | 'volatile' ;

also_keyword:
   (
	t='add' | t='alias' | t='assembly' | t='module' | t='field' | t='method' | t='param' | t='property' | t='type' | t='yield'
	| t='from' | t='into' | t='join' | t='on' | t='where' | t='orderby' | t='group' | t='by' | t='ascending' | t='descending' 
	| t='equals' | t='select' | t='pragma' | t='let' | t='remove' | t='get' | t='set' | t='var' | t='__arglist' | t='dynamic' | t='elif' 
	| t='endif' | t='define' | t='undef' | t='extends'
   ) -> string(payload={$t.text})
;

literal:
	Real_literal -> string(payload={$Real_literal.text}) 
	| NUMBER -> string(payload={$NUMBER.text}) 
	| LONGNUMBER -> string(payload={$LONGNUMBER.text + "L"}) 
	| Hex_number -> string(payload={$Hex_number.text}) 
	| Character_literal -> string(payload={$Character_literal.text}) 
	| STRINGLITERAL -> string(payload={ $STRINGLITERAL.text }) 
	| Verbatim_string_literal -> verbatim_string(payload={ escapeJavaString($Verbatim_string_literal.text.Substring(1)) }) 
	| TRUE -> string(payload={"true"}) 
	| FALSE -> string(payload={"false"}) 
	| NULL -> string(payload={"null"}) 
	;

