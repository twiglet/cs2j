/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;
using System.Collections.Generic;
using Twiglet.CS2J.Translator.Utils;
using System.IO;

namespace Twiglet.CS2J.Translator
{
	public class CS2JSettings
	{
		
            public bool DisplayTokens { get; set; }

            // dump parse trees to stdout
            public bool DumpCSharp { get; set; }
            public bool DumpJavaSyntax { get; set; }
            public bool DumpJava { get; set; }

            public bool DumpXmls { get; set; }
            public bool DumpEnums { get; set; }
            public string OutDir { get; set; }
            public string CheatDir { get; set; }
            public IList<string> NetRoot { get; set; }
            public IList<string> ExNetRoot { get; set; }
            public IList<string> NetSchemaDir { get; set; }
            public IList<string> AppRoot { get; set; }
            public IList<string> ExAppRoot { get; set; }
            public IList<string> Exclude { get; set; }
            public IList<string> MacroDefines { get; set; }
            public string XmlDir { get; set; }
            public string EnumDir { get; set; }
            public int Verbosity { get; set; }
            
            public string KeyFile { get; set; }

            public bool DebugTemplateExtraction { get; set; }
            public int DebugLevel { get; set; }
            
            public bool Warnings { get; set; }
            public bool WarningsFailedResolves { get; set; }

            public bool TranslatorKeepParens
            {
                get; set;
            }

            public bool TranslatorAddTimeStamp
            {
                get; set;
            }

            public bool TranslatorExceptionIsThrowable
            {
                get; set;
            }

            public bool TranslatorBlanketThrow
            {
                get; set;
            }

            public bool TranslatorMakeJavadocComments
            {
                get; set;
            }

            public bool TranslatorMakeJavaNamingConventions
            {
                get; set;
            }

            public bool EnumsAsNumericConsts
            {
                get; set;
            }

            public bool UnsignedNumbersToSigned
            {
                get; set;
            }

            public bool ExperimentalTransforms
            {
                get; set;
            }

           public bool InternalIsJavaish
           {
              get; set;
           }

            public CS2JSettings ()
            {
		
                DisplayTokens = false;
                
                // dump parse trees to stdout
	        DumpCSharp = false;
	        DumpJavaSyntax = false;
	        DumpJava = false;
	
	        DumpXmls = false;
	        DumpEnums = false;
	        OutDir = Directory.GetCurrentDirectory();
	        CheatDir = "";
	        NetRoot = new List<string>();
	        ExNetRoot = new List<string>();
	        NetSchemaDir = new List<string>();
	        AppRoot = new List<string>();
	        ExAppRoot = new List<string>();
	        Exclude = new List<string>();
	        MacroDefines = new List<string>();
	        XmlDir = Path.Combine(Directory.GetCurrentDirectory(), "tmpXMLs");
                EnumDir = Path.Combine(Directory.GetCurrentDirectory(), "enums");
                KeyFile = null;
	        Verbosity = 0;	
                DebugTemplateExtraction = true;	
	        DebugLevel = 1;		
	        Warnings = true;		
	        WarningsFailedResolves = false;		

                TranslatorKeepParens = true;
                TranslatorAddTimeStamp = true;
                TranslatorExceptionIsThrowable = false;
                TranslatorBlanketThrow = true;
                TranslatorMakeJavadocComments = true;
                TranslatorMakeJavaNamingConventions = true;

                EnumsAsNumericConsts = false;
                UnsignedNumbersToSigned = false;

                ExperimentalTransforms = false;

                InternalIsJavaish = false;
            }
	}
}

