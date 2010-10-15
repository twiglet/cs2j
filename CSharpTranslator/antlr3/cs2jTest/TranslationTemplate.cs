using System;
using NUnit.Framework;
using System.IO;
using System.Xml.Serialization;
using RusticiSoftware.Translator.Utils;
using System.Xml;
using System.Text;
using System.Collections.Generic;

namespace RusticiSoftware.Translator.CLR
{
	[TestFixture()]
	public class TranslationTemplateTest
	{
		
		private TypeRepTemplate ToStreamAndBack(TypeRepTemplate inT) {
			
			XmlSerializer xmls = new XmlSerializer(inT.GetType(), Constants.TranslationTemplateNamespace);

			using (MemoryStream ms = new MemoryStream())
    		{
        		XmlWriterSettings settings = new XmlWriterSettings();
        		settings.Encoding = Encoding.UTF8;
        		settings.Indent = true;
        		settings.IndentChars = "\t";
        		settings.NewLineChars = Environment.NewLine;
        		settings.ConformanceLevel = ConformanceLevel.Document;

        		using (XmlWriter writer = XmlTextWriter.Create(ms, settings))
        		{
            		xmls.Serialize(writer, inT);
        		}

#if VERBOSETESTS
				string xml = Encoding.UTF8.GetString(ms.ToArray());
				Console.WriteLine (xml);
#endif    

				//ms.Flush();
				ms.Position = 0;
			
				return TypeRepTemplate.newInstance(ms);
			}
		}
		
		[Test()]
		public void EnumCase ()
		{
			EnumRepTemplate to = new EnumRepTemplate();
			
			to.Members.Add(new EnumMemberRepTemplate("START"));
			to.Members.Add(new EnumMemberRepTemplate("EOF","3"));		
			
			EnumRepTemplate back = (EnumRepTemplate)ToStreamAndBack(to);

			Assert.AreEqual(to, back);
		}

		[Test()]
		public void DelegateCase ()
		{
			DelegateRepTemplate to = new DelegateRepTemplate();
			
			to.Return = "System.String";
			List<ParamRepTemplate> parms = to.Params;
			parms.Add(new ParamRepTemplate("System.Int32", "count"));
			parms.Add(new ParamRepTemplate("System.Object", "fill"));
			parms.Add(new ParamRepTemplate("System.Boolean", "verbose"));
			to.Java = "fred";
			
			DelegateRepTemplate back = (DelegateRepTemplate)ToStreamAndBack(to);

			Assert.AreEqual(to, back);
		}
}
}

