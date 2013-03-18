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
using System.Collections.Generic;
using Twiglet.CS2J.Translator.Utils;
using System.IO;

namespace Twiglet.CS2J.Translator
{
        public class CS2JOption<T>
        {
           private bool isDefault = true;
           public bool IsDefault
           {
              get
              {
                 return isDefault;
              }
           }
           private T optValue = default(T);
           public T Value
           {
              get
              {
                 return optValue;
              }
              set
              {
                 optValue = value;
                 isDefault = false;
              }
           }
           public void SetIfDefault(T newVal)
           {
              if (IsDefault)
              {
                 optValue = newVal;
              }
           }
     
           public void SetDefault(T newVal)
           {
              optValue = newVal;
           }

        }

        public class CS2JOptionStrings : CS2JOption<IList<string>>
        {
           public void Add(IList<string> newVal)
           {
              if (IsDefault)
              {
                 Value = newVal;
              }
              else
              {
                 foreach (string s in newVal)
                 {
                    Value.Add(s);
                 }
              }
           }
        }

	public class CS2JSettings
	{
	
            // DisplayTokens
            private CS2JOption<bool> optDisplayTokens = new CS2JOption<bool>();
            public CS2JOption<bool> OptDisplayTokens { 
               get
               {
                  return optDisplayTokens;
               }
            }
            public bool DisplayTokens { 
               get
               { 
                  return optDisplayTokens.Value; 
               }
               set
               {
                  optDisplayTokens.Value = value;
               }
            }

            // DumpCSharp
            private CS2JOption<bool> optDumpCSharp = new CS2JOption<bool>();
            public CS2JOption<bool> OptDumpCSharp { 
               get
               {
                  return optDumpCSharp;
               }
            }
            public bool DumpCSharp { 
               get
               { 
                  return optDumpCSharp.Value; 
               }
               set
               {
                  optDumpCSharp.Value = value;
               }
            }

            // DumpJavaSyntax
            private CS2JOption<bool> optDumpJavaSyntax = new CS2JOption<bool>();
            public CS2JOption<bool> OptDumpJavaSyntax { 
               get
               {
                  return optDumpJavaSyntax;
               }
            }
            public bool DumpJavaSyntax { 
               get
               { 
                  return optDumpJavaSyntax.Value; 
               }
               set
               {
                  optDumpJavaSyntax.Value = value;
               }
            }

            // DumpJava
            private CS2JOption<bool> optDumpJava = new CS2JOption<bool>();
            public CS2JOption<bool> OptDumpJava { 
               get
               {
                  return optDumpJava;
               }
            }
            public bool DumpJava { 
               get
               { 
                  return optDumpJava.Value; 
               }
               set
               {
                  optDumpJava.Value = value;
               }
            }

            // DumpXmls
            private CS2JOption<bool> optDumpXmls = new CS2JOption<bool>();
            public CS2JOption<bool> OptDumpXmls { 
               get
               {
                  return optDumpXmls;
               }
            }
            public bool DumpXmls { 
               get
               { 
                  return optDumpXmls.Value; 
               }
               set
               {
                  optDumpXmls.Value = value;
               }
            }

            // DumpEnums
            private CS2JOption<bool> optDumpEnums = new CS2JOption<bool>();
            public CS2JOption<bool> OptDumpEnums { 
               get
               {
                  return optDumpEnums;
               }
            }
            public bool DumpEnums { 
               get
               { 
                  return optDumpEnums.Value; 
               }
               set
               {
                  optDumpEnums.Value = value;
               }
            }

            // OutDir
            private CS2JOption<string> optOutDir = new CS2JOption<string>();
            public CS2JOption<string> OptOutDir { 
               get
               {
                  return optOutDir;
               }
            }
            public string OutDir { 
               get
               { 
                  return optOutDir.Value; 
               }
               set
               {
                  optOutDir.Value = value;
               }
            }

            // CheatDir
            private CS2JOption<string> optCheatDir = new CS2JOption<string>();
            public CS2JOption<string> OptCheatDir { 
               get
               {
                  return optCheatDir;
               }
            }
            public string CheatDir { 
               get
               { 
                  return optCheatDir.Value; 
               }
               set
               {
                  optCheatDir.Value = value;
               }
            }

            // NetRoot
            private CS2JOptionStrings optNetRoot = new CS2JOptionStrings();
            public CS2JOptionStrings OptNetRoot { 
               get
               {
                  return optNetRoot;
               }
            }
            public IList<string> NetRoot { 
               get
               { 
                  return optNetRoot.Value; 
               }
               set
               {
                  optNetRoot.Value = value;
               }
            }

            // ExNetRoot
            private CS2JOptionStrings optExNetRoot = new CS2JOptionStrings();
            public CS2JOptionStrings OptExNetRoot { 
               get
               {
                  return optExNetRoot;
               }
            }
            public IList<string> ExNetRoot { 
               get
               { 
                  return optExNetRoot.Value; 
               }
               set
               {
                  optExNetRoot.Value = value;
               }
            }

            // NetSchemaDir
            private CS2JOptionStrings optNetSchemaDir = new CS2JOptionStrings();
            public CS2JOptionStrings OptNetSchemaDir { 
               get
               {
                  return optNetSchemaDir;
               }
            }
            public IList<string> NetSchemaDir { 
               get
               { 
                  return optNetSchemaDir.Value; 
               }
               set
               {
                  optNetSchemaDir.Value = value;
               }
            }

            // AppRoot
            private CS2JOptionStrings optAppRoot = new CS2JOptionStrings();
            public CS2JOptionStrings OptAppRoot { 
               get
               {
                  return optAppRoot;
               }
            }
            public IList<string> AppRoot { 
               get
               { 
                  return optAppRoot.Value; 
               }
               set
               {
                  optAppRoot.Value = value;
               }
            }

            // ExAppRoot
            private CS2JOptionStrings optExAppRoot = new CS2JOptionStrings();
            public CS2JOptionStrings OptExAppRoot { 
               get
               {
                  return optExAppRoot;
               }
            }
            public IList<string> ExAppRoot { 
               get
               { 
                  return optExAppRoot.Value; 
               }
               set
               {
                  optExAppRoot.Value = value;
               }
            }

            // CsDir
            private CS2JOptionStrings optCsDir = new CS2JOptionStrings();
            public CS2JOptionStrings OptCsDir { 
               get
               {
                  return optCsDir;
               }
            }
            public IList<string> CsDir { 
               get
               { 
                  return optCsDir.Value; 
               }
               set
               {
                  optCsDir.Value = value;
               }
            }

            // ExCsDir
            private CS2JOptionStrings optExCsDir = new CS2JOptionStrings();
            public CS2JOptionStrings OptExCsDir { 
               get
               {
                  return optExCsDir;
               }
            }
            public IList<string> ExCsDir { 
               get
               { 
                  return optExCsDir.Value; 
               }
               set
               {
                  optExCsDir.Value = value;
               }
            }

            // MacroDefines
            private CS2JOptionStrings optMacroDefines = new CS2JOptionStrings();
            public CS2JOptionStrings OptMacroDefines { 
               get
               {
                  return optMacroDefines;
               }
            }
            public IList<string> MacroDefines { 
               get
               { 
                  return optMacroDefines.Value; 
               }
               set
               {
                  optMacroDefines.Value = value;
               }
            }

            // AltTranslations
            private CS2JOptionStrings optAltTranslations = new CS2JOptionStrings();
            public CS2JOptionStrings OptAltTranslations { 
               get
               {
                  return optAltTranslations;
               }
            }
            public IList<string> AltTranslations { 
               get
               { 
                  return optAltTranslations.Value; 
               }
               set
               {
                  optAltTranslations.Value = value;
               }
            }

            // XmlDir
            private CS2JOption<string> optXmlDir = new CS2JOption<string>();
            public CS2JOption<string> OptXmlDir { 
               get
               {
                  return optXmlDir;
               }
            }
            public string XmlDir { 
               get
               { 
                  return optXmlDir.Value; 
               }
               set
               {
                  optXmlDir.Value = value;
               }
            }

            // EnumDir
            private CS2JOption<string> optEnumDir = new CS2JOption<string>();
            public CS2JOption<string> OptEnumDir { 
               get
               {
                  return optEnumDir;
               }
            }
            public string EnumDir { 
               get
               { 
                  return optEnumDir.Value; 
               }
               set
               {
                  optEnumDir.Value = value;
               }
            }

            // Verbosity
            private CS2JOption<int> optVerbosity = new CS2JOption<int>();
            public CS2JOption<int> OptVerbosity { 
               get
               {
                  return optVerbosity;
               }
            }
            public int Verbosity { 
               get
               { 
                  return optVerbosity.Value; 
               }
               set
               {
                  optVerbosity.Value = value;
               }
            }

            // KeyFile
            private CS2JOption<string> optKeyFile = new CS2JOption<string>();
            public CS2JOption<string> OptKeyFile { 
               get
               {
                  return optKeyFile;
               }
            }
            public string KeyFile { 
               get
               { 
                  return optKeyFile.Value; 
               }
               set
               {
                  optKeyFile.Value = value;
               }
            }

            // DebugTemplateExtraction
            private CS2JOption<bool> optDebugTemplateExtraction = new CS2JOption<bool>();
            public CS2JOption<bool> OptDebugTemplateExtraction { 
               get
               {
                  return optDebugTemplateExtraction;
               }
            }
            public bool DebugTemplateExtraction { 
               get
               { 
                  return optDebugTemplateExtraction.Value; 
               }
               set
               {
                  optDebugTemplateExtraction.Value = value;
               }
            }

            // DebugLevel
            private CS2JOption<int> optDebugLevel = new CS2JOption<int>();
            public CS2JOption<int> OptDebugLevel { 
               get
               {
                  return optDebugLevel;
               }
            }
            public int DebugLevel { 
               get
               { 
                  return optDebugLevel.Value; 
               }
               set
               {
                  optDebugLevel.Value = value;
               }
            }

            // Warnings
            private CS2JOption<bool> optWarnings = new CS2JOption<bool>();
            public CS2JOption<bool> OptWarnings { 
               get
               {
                  return optWarnings;
               }
            }
            public bool Warnings { 
               get
               { 
                  return optWarnings.Value; 
               }
               set
               {
                  optWarnings.Value = value;
               }
            }

            // WarningsFailedResolves
            private CS2JOption<bool> optWarningsFailedResolves = new CS2JOption<bool>();
            public CS2JOption<bool> OptWarningsFailedResolves { 
               get
               {
                  return optWarningsFailedResolves;
               }
            }
            public bool WarningsFailedResolves { 
               get
               { 
                  return optWarningsFailedResolves.Value; 
               }
               set
               {
                  optWarningsFailedResolves.Value = value;
               }
            }

            // TranslatorKeepParens
            private CS2JOption<bool> optTranslatorKeepParens = new CS2JOption<bool>();
            public CS2JOption<bool> OptTranslatorKeepParens { 
               get
               {
                  return optTranslatorKeepParens;
               }
            }
            public bool TranslatorKeepParens { 
               get
               { 
                  return optTranslatorKeepParens.Value; 
               }
               set
               {
                  optTranslatorKeepParens.Value = value;
               }
            }

            // TranslatorAddTimeStamp
            private CS2JOption<bool> optTranslatorAddTimeStamp = new CS2JOption<bool>();
            public CS2JOption<bool> OptTranslatorAddTimeStamp { 
               get
               {
                  return optTranslatorAddTimeStamp;
               }
            }
            public bool TranslatorAddTimeStamp { 
               get
               { 
                  return optTranslatorAddTimeStamp.Value; 
               }
               set
               {
                  optTranslatorAddTimeStamp.Value = value;
               }
            }

            // TranslatorExceptionIsThrowable
            private CS2JOption<bool> optTranslatorExceptionIsThrowable = new CS2JOption<bool>();
            public CS2JOption<bool> OptTranslatorExceptionIsThrowable { 
               get
               {
                  return optTranslatorExceptionIsThrowable;
               }
            }
            public bool TranslatorExceptionIsThrowable { 
               get
               { 
                  return optTranslatorExceptionIsThrowable.Value; 
               }
               set
               {
                  optTranslatorExceptionIsThrowable.Value = value;
               }
            }

            // TranslatorBlanketThrow
            private CS2JOption<bool> optTranslatorBlanketThrow = new CS2JOption<bool>();
            public CS2JOption<bool> OptTranslatorBlanketThrow { 
               get
               {
                  return optTranslatorBlanketThrow;
               }
            }
            public bool TranslatorBlanketThrow { 
               get
               { 
                  return optTranslatorBlanketThrow.Value; 
               }
               set
               {
                  optTranslatorBlanketThrow.Value = value;
               }
            }

            // TranslatorMakeJavadocComments
            private CS2JOption<bool> optTranslatorMakeJavadocComments = new CS2JOption<bool>();
            public CS2JOption<bool> OptTranslatorMakeJavadocComments { 
               get
               {
                  return optTranslatorMakeJavadocComments;
               }
            }
            public bool TranslatorMakeJavadocComments { 
               get
               { 
                  return optTranslatorMakeJavadocComments.Value; 
               }
               set
               {
                  optTranslatorMakeJavadocComments.Value = value;
               }
            }

            // TranslatorMakeJavaNamingConventions
            private CS2JOption<bool> optTranslatorMakeJavaNamingConventions = new CS2JOption<bool>();
            public CS2JOption<bool> OptTranslatorMakeJavaNamingConventions { 
               get
               {
                  return optTranslatorMakeJavaNamingConventions;
               }
            }
            public bool TranslatorMakeJavaNamingConventions { 
               get
               { 
                  return optTranslatorMakeJavaNamingConventions.Value; 
               }
               set
               {
                  optTranslatorMakeJavaNamingConventions.Value = value;
               }
            }

            // EnumsAsNumericConsts
            private CS2JOption<bool> optEnumsAsNumericConsts = new CS2JOption<bool>();
            public CS2JOption<bool> OptEnumsAsNumericConsts { 
               get
               {
                  return optEnumsAsNumericConsts;
               }
            }
            public bool EnumsAsNumericConsts { 
               get
               { 
                  return optEnumsAsNumericConsts.Value; 
               }
               set
               {
                  optEnumsAsNumericConsts.Value = value;
               }
            }

            // UnsignedNumbersToSigned
            private CS2JOption<bool> optUnsignedNumbersToSigned = new CS2JOption<bool>();
            public CS2JOption<bool> OptUnsignedNumbersToSigned { 
               get
               {
                  return optUnsignedNumbersToSigned;
               }
            }
            public bool UnsignedNumbersToSigned { 
               get
               { 
                  return optUnsignedNumbersToSigned.Value; 
               }
               set
               {
                  optUnsignedNumbersToSigned.Value = value;
               }
            }

            // UnsignedNumbersToBiggerSignedNumbers
            private CS2JOption<bool> optUnsignedNumbersToBiggerSignedNumbers = new CS2JOption<bool>();
            public CS2JOption<bool> OptUnsignedNumbersToBiggerSignedNumbers { 
               get
               {
                  return optUnsignedNumbersToBiggerSignedNumbers;
               }
            }
            public bool UnsignedNumbersToBiggerSignedNumbers { 
               get
               { 
                  return optUnsignedNumbersToBiggerSignedNumbers.Value; 
               }
               set
               {
                  optUnsignedNumbersToBiggerSignedNumbers.Value = value;
               }
            }

            // ExperimentalTransforms
            private CS2JOption<bool> optExperimentalTransforms = new CS2JOption<bool>();
            public CS2JOption<bool> OptExperimentalTransforms { 
               get
               {
                  return optExperimentalTransforms;
               }
            }
            public bool ExperimentalTransforms { 
               get
               { 
                  return optExperimentalTransforms.Value; 
               }
               set
               {
                  optExperimentalTransforms.Value = value;
               }
            }

            // InternalIsJavaish
            private CS2JOption<bool> optInternalIsJavaish = new CS2JOption<bool>();
            public CS2JOption<bool> OptInternalIsJavaish { 
               get
               {
                  return optInternalIsJavaish;
               }
            }
            public bool InternalIsJavaish { 
               get
               { 
                  return optInternalIsJavaish.Value; 
               }
               set
               {
                  optInternalIsJavaish.Value = value;
               }
            }

            public CS2JSettings ()
            {
		
               OptDisplayTokens.SetDefault(false);
                
                // dump parse trees to stdout
	        OptDumpCSharp.SetDefault(false);
	        OptDumpJavaSyntax.SetDefault(false);
	        OptDumpJava.SetDefault(false);
	
	        OptDumpXmls.SetDefault(false);
	        OptDumpEnums.SetDefault(false);
	        OptOutDir.SetDefault(Directory.GetCurrentDirectory());
	        OptCheatDir.SetDefault("");
	        OptNetRoot.SetDefault(new List<string>());
	        OptExNetRoot.SetDefault(new List<string>());
	        OptNetSchemaDir.SetDefault(new List<string>());
	        OptAppRoot.SetDefault(new List<string>());
	        OptExAppRoot.SetDefault(new List<string>());
	        OptCsDir.SetDefault(new List<string>());
	        OptExCsDir.SetDefault(new List<string>());
	        OptMacroDefines.SetDefault(new List<string>());
	        OptAltTranslations.SetDefault(new List<string>());
	        OptXmlDir.SetDefault(Path.Combine(Directory.GetCurrentDirectory(), "tmpXMLs"));
                OptEnumDir.SetDefault(Path.Combine(Directory.GetCurrentDirectory(), "enums"));
                OptKeyFile.SetDefault(null);
	        OptVerbosity.SetDefault(0);	
                OptDebugTemplateExtraction.SetDefault(true);	
	        OptDebugLevel.SetDefault(1);		
	        OptWarnings.SetDefault(true);		
	        OptWarningsFailedResolves.SetDefault(false);		

                OptTranslatorKeepParens.SetDefault(true);
                OptTranslatorAddTimeStamp.SetDefault(true);
                OptTranslatorExceptionIsThrowable.SetDefault(false);
                OptTranslatorBlanketThrow.SetDefault(true);
                OptTranslatorMakeJavadocComments.SetDefault(true);
                OptTranslatorMakeJavaNamingConventions.SetDefault(true);

                OptEnumsAsNumericConsts.SetDefault(false);
                OptUnsignedNumbersToSigned.SetDefault(false);
                OptUnsignedNumbersToBiggerSignedNumbers.SetDefault(false);

                OptExperimentalTransforms.SetDefault(false);

                OptInternalIsJavaish.SetDefault(false);
            }
	}
}

