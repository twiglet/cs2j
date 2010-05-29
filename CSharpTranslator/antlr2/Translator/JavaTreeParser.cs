
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using T = RusticiSoftware.Translator.CSharpJavaTokenTypes;  // We want easy access to the Token mappings

namespace RusticiSoftware.Translator
{
    // Generate header specific to the tree-parser CSharp file
    using System;

    using TreeParser = antlr.TreeParser;
    using Token = antlr.Token;
    using IToken = antlr.IToken;
    using AST = antlr.collections.AST;
    using RecognitionException = antlr.RecognitionException;
    using ANTLRException = antlr.ANTLRException;
    using NoViableAltException = antlr.NoViableAltException;
    using MismatchedTokenException = antlr.MismatchedTokenException;
    using SemanticException = antlr.SemanticException;
    using BitSet = antlr.collections.impl.BitSet;
    using ASTPair = antlr.ASTPair;
    using ASTFactory = antlr.ASTFactory;
    using ASTArray = antlr.collections.impl.ASTArray;


    /** Java 1.3 AST Tree Parser Base Class
     *
     * Author: Kevin Glynn <kevin.glynn@scorm.com>
     *
     * This contains utility routines for the java parser passes
     *
     */
    public class JavaTreeParser : antlr.TreeParser
    {

        protected string ClassInProcess;              // Name of Class being processed
        /// <summary>
        /// Provides the storage for elements in the <c>Set</c>, stored as the key-set
        /// of the <c>IDictionary</c> object.  Set this object in the constructor
        /// if you create your own <c>Set</c> class.  
        /// </summary>
        protected Set<string> imports = null;

        private static readonly string[] ScruTypeStrs = new string[] { "System.Int32",
																	   "System.Int64",
																       "System.Char",
																	   "System.Enum", };

        protected void initialize()
        {
            // Here we can add imports that should always be present
            imports = new Set<string>();
        }

        protected void addImport(string imp)
        {
            imports.Add(imp);
        }

        protected void addImport(string[] imps)
        {
            foreach (string imp in imps) 
               imports.Add(imp);
        }

        protected ASTNode GetImports()
        {
            ASTNode ret = (ASTNode)astFactory.make((AST)(ASTNode)astFactory.create(T.IMPORTS, "IMPORTS"));
            String[] sortedImports = imports.AsArray();
            Array.Sort(sortedImports);
            foreach (string imp in sortedImports)
            {
                ret.addChild((ASTNode)astFactory.make((AST)(ASTNode)astFactory.create(T.IMPORT, "import"),
                                                      (AST)(ASTNode)astFactory.make((AST)(ASTNode)astFactory.create(T.IDENTIFIER, imp))));
            }
            return ret;
        }

        protected bool isValidScrutinee(ASTNode e)
        {
            bool ret = false;
            TypeRep stype = e.DotNetType;

            foreach (string t in ScruTypeStrs)
            {
                if (mkType(t).IsA(stype))
                {
                    ret = true;
                    break;
                }
            }

            return ret;
        }


        // getClassName, getPackageName assume a compilation unit looks like this:
        // #( COMPILATION_UNIT, 
        //     #(PACKAGE_DEF, <namespace>), 
        //     #(USING_DIRECTIVES, (<imports>)*), 
        //     #(class, MODIFIERS, <Class Name>, ....)
        //  )
        public static String getClassName(ASTNode cuAST)
        {
            if (cuAST.Type == T.COMPILATION_UNIT)
            {
                AST cla = cuAST.getFirstChild().getNextSibling().getNextSibling().getNextSibling(); ;
                return cla.getFirstChild().getNextSibling().getText();
            }
            else
            {
                throw new CorruptCompilationUnit(cuAST);
            }
        }

        public static ArrayList getPackageName(ASTNode cuAST)
        {

            if (cuAST.Type == T.COMPILATION_UNIT)
            {
                ArrayList nsComps = new ArrayList();
                AST ns = cuAST.getFirstChild().getFirstChild();
                while (ns != null)
                {
                    if (ns.Type == T.IDENTIFIER)
                    {
                        nsComps.Add(ns.getText());
                        break;
                    }
                    else
                    {   // Its a DOT node
                        ns = ns.getFirstChild();
                        nsComps.Add(ns.getText());
                        ns = ns.getNextSibling();
                    }
                }
                return nsComps;
            }
            else
            {
                throw new CorruptCompilationUnit(cuAST);
            }
        }

        // Keep track of current use Path
        protected Stack usePath = null;

        protected string[] CollectUsePath()
        {
            int count = 0;
            foreach (ArrayList l in usePath)
            {
                count += l.Count;
            }

            string[] ret = new string[count];
            int i = 0;

            foreach (ArrayList l in usePath)
            {
                foreach (string s in l)
                {
                    ret[i] = s;
                    i++;
                }
            }

            return ret;
        }
        
        public String idToString(AST idAST, string sep)
        {

            String res = "";

            while (idAST != null)
            {
                if (idAST.Type == T.IDENTIFIER)
                {
                    res += idAST.getText();
                    break;
                }
                else if (idAST.Type == T.DOT)
                {
                    idAST = (ASTNode)idAST.getFirstChild();
                    res += idAST.getText() + sep;
                    idAST = (ASTNode)idAST.getNextSibling();
                }
                else
                {
                    throw new UnexpectedAST((ASTNode)idAST);
                }
            }

            return res;
        }

        public String idToString(AST idAST, char sep)
        {
            return idToString(idAST, sep.ToString());
        }
 
        public String idToString(AST idAST)
        {
            return idToString(idAST, ".");
        }
        
        // typeSpec [TextWriter w]
        // :	#(TYPE 
        //			( 	identifier[w]
        //			| 	builtInType[w]
        //			)
        //			rankSpecifiers[w]			
        //		)
        public String typeToString(AST tyAST, bool withQuotes)
        {
            String res = "";

            if (withQuotes)
               res = "\"";

            if (tyAST != null && tyAST.Type == T.TYPE)
            {

                tyAST = tyAST.getFirstChild();
                if (tyAST.Type == T.DOT)
                    res += idToString(tyAST);
                else
                    res += tyAST.getText();

                // Move to rankspecifiers  
                tyAST = tyAST.getNextSibling();
                for (int i = 0; i < tyAST.getNumberOfChildren(); i++)
                    res += "[]";

            }
            else
            {
                throw new UnexpectedAST((ASTNode)tyAST);
            }

            if (withQuotes)
                res += "\"";

            return res;
        }

        public String typeToString(AST tyAST)
        {
            return typeToString(tyAST, true);
        }

        // Remove/Replace troublesome characters
        protected String typeNameToId(String tName)
        {
            return tName.Replace(".", "").Replace("[","_").Replace("]","");
        }

        protected void prependStringToId(AST idAST, String str)
        {
            while (idAST.Type == T.DOT)
            {
                idAST = idAST.getFirstChild().getNextSibling();
            }
            idAST.setText(str + idAST.getText());
        }

        private readonly static string[] javaReserved = new string[] { "int", "protected", "package" };

        protected void fixBrokenIds(ASTNode id)
        {
            if (id.Type == T.IDENTIFIER)
            {
                foreach (string k in javaReserved)
                {
                   if (k == id.getText()) 
                   {
                       id.setText("__" + id.getText());
                       break;
                   }
                }
            }
        }

        protected string escapeJavaString(string rawStr)
        {
            StringBuilder buf = new StringBuilder(rawStr.Length * 2);
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
            return buf.ToString();
        }

        protected Stack uPath = new Stack();

        protected TypeRep mkType(string type)
        {
            return TypeRep.newInstance(type, uPath);
        }

        public ASTNode stripQualifier(ASTNode eAST)
        {
            if (eAST.Type == T.IDENTIFIER)
                return (ASTNode) astFactory.dupTree(eAST);
            else
                return stripQualifier((ASTNode)eAST.getFirstChild().getNextSibling());
        }

    }


}
