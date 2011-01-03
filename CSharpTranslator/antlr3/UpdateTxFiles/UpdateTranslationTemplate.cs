using System;
using RusticiSoftware.Translator;
using OldT = RusticiSoftware.Translator.TypeRepTemplate;
using NewT = RusticiSoftware.Translator.CLR.TypeRepTemplate;

namespace UpdateTxFiles
{
	public class UpdateTranslationTemplate {
		
		public UpdateTranslationTemplate ()
		{
		}
		public NewT upgrade (OldT inTemplate)
		{
			throw new System.NotImplementedException ();
		}
	
	}
}

