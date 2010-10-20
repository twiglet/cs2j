using System;
using System.Reflection;
using RusticiSoftware.Translator.CLR;
using System.IO;
using System.Xml.Serialization;
using System.Xml;
using RusticiSoftware.Translator.Utils;
using System.Text;
using NDesk.Options;
using System.Collections.Generic;
namespace cs2j.Template.Utils
{
	public class TemplateFromDLL
	{
		private Assembly assembly = null;		
		private int verbose = 0;
		
		public TemplateFromDLL (string DLLFileName)
		{
			assembly = Assembly.LoadFile(DLLFileName);
		}
		
		public TemplateFromDLL ()
		{
		}
		
		
		public void listTypes(string DLLFileName) {
			
			Assembly testAssembly = Assembly.LoadFile(DLLFileName);
			
			Type[] exportedTypes = testAssembly.GetExportedTypes();
			
			Console.WriteLine ("Enums:");
			foreach (Type item in exportedTypes) {
				if (item.IsEnum) {
					Console.WriteLine (" * " + TypeHelper.buildTypeName(item));
				}
			}
			
			Console.WriteLine ("Interfaces:");
			foreach (Type item in exportedTypes) {
				if (item.IsInterface) {
					Console.WriteLine (" * " + TypeHelper.buildTypeName(item));
				}
			}
			Console.WriteLine ("Classes:");
			foreach (Type item in exportedTypes) {
				if (item.IsClass) {
					Console.WriteLine (" * " + TypeHelper.buildTypeName(item));
				}
			}
			Console.WriteLine ("Arrays:");
			foreach (Type item in exportedTypes) {
				if (item.IsArray) {
					Console.WriteLine (" * " + TypeHelper.buildTypeName(item));
				}
			}
			Console.WriteLine ("Others:");
			foreach (Type item in exportedTypes) {
				if (!item.IsEnum && !item.IsInterface && !item.IsClass && !item.IsArray) {
					Console.WriteLine (" * " + TypeHelper.buildTypeName(item));
				}
			}	

		}
		
		private void buildParameters(ConstructorRepTemplate c, MethodBase m) {				
			foreach (ParameterInfo p in m.GetParameters()) {
				ParamRepTemplate paramRep = new ParamRepTemplate();
				paramRep.Type = TypeHelper.buildTypeName(p.ParameterType);
				paramRep.Name = p.Name;
				c.Params.Add(paramRep);
			}
		}

		private void buildInterface(InterfaceRepTemplate iface, Type t) {				
			
			if (t.IsGenericType) {
				iface.TypeName = t.GetGenericTypeDefinition().FullName;
				string[] tParams = new string[t.GetGenericArguments().Length];
				for (int i = 0; i < t.GetGenericArguments().Length; i++) {
					tParams[i] = t.GetGenericArguments()[i].Name;
				}
				iface.TypeParams = tParams;
			}
			else {
				iface.TypeName = t.FullName;
			}
			
			List<String> bases = new List<String>();
			if (t.BaseType != null)
				bases.Add(TypeHelper.buildTypeName(t.BaseType));
			foreach (Type iTy in t.GetInterfaces()) {
				bases.Add(TypeHelper.buildTypeName(iTy));
			}
			
			iface.Inherits = bases.ToArray();
			
			// Grab Methods
			foreach (MethodInfo m in t.GetMethods(BindingFlags.DeclaredOnly | BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance)) {
				if (m.IsSpecialName) {
					// e.g., a property's getter / setter method
					continue;
				}
				MethodRepTemplate methRep = new MethodRepTemplate();
				methRep.Name = m.Name;
				methRep.Return = TypeHelper.buildTypeName(m.ReturnType);
				if (m.IsGenericMethod) {
					string[] tParams = new string[m.GetGenericArguments().Length];
					for (int i = 0; i < m.GetGenericArguments().Length; i++) {
						tParams[i] = m.GetGenericArguments()[i].Name;
					}
					methRep.TypeParams = tParams;
				}
				buildParameters(methRep, m);
				if (m.IsStatic) {
					methRep.IsStatic = true;
				}
				methRep.SurroundingTypeName = iface.TypeName;
				iface.Methods.Add(methRep);
			}
			
			// Grab Properties
			foreach (PropertyInfo p in t.GetProperties()) {
				PropRepTemplate propRep = new PropRepTemplate();
				propRep.Name = p.Name;
				propRep.Type = TypeHelper.buildTypeName(p.PropertyType);
				propRep.CanRead = p.CanRead;
				propRep.CanWrite = p.CanWrite;			
				iface.Properties.Add(propRep);
			}

			// Grab Events
			foreach (EventInfo e in t.GetEvents()) {
				FieldRepTemplate eventRep = new FieldRepTemplate();
				eventRep.Name = e.Name;
				eventRep.Type = TypeHelper.buildTypeName(e.EventHandlerType);
				iface.Events.Add(eventRep);
			}
		}

		private void buildClass(ClassRepTemplate klass, Type t) {	
			// Grab common fields
			buildInterface(klass, t);
			// Grab Constructors
			foreach (ConstructorInfo c in t.GetConstructors()) {
				ConstructorRepTemplate consRep = new ConstructorRepTemplate();
				buildParameters(consRep, c);
				consRep.SurroundingTypeName = klass.TypeName;
				klass.Constructors.Add(consRep);
			}
			// Grab Fields
			foreach (FieldInfo f in t.GetFields()) {
				FieldRepTemplate fieldRep = new FieldRepTemplate();
				fieldRep.Name = f.Name;
				fieldRep.Type = TypeHelper.buildTypeName(f.FieldType);
				klass.Fields.Add(fieldRep);
			}
			// Grab Casts
			foreach (MethodInfo m in t.GetMethods(BindingFlags.DeclaredOnly | BindingFlags.Public | BindingFlags.Static )) {
				if (m.IsSpecialName && (m.Name == "op_Explicit" || m.Name == "op_Implicit")) {
					CastRepTemplate cast = new CastRepTemplate();
					cast.To = TypeHelper.buildTypeName(m.ReturnType);
					cast.From = TypeHelper.buildTypeName(m.GetParameters()[0].ParameterType);
					klass.Casts.Add(cast);
				}

			}

		}
		
		private IList<TypeRepTemplate> mkTemplates(string typeName) {
			
			List<TypeRepTemplate> rets = new List<TypeRepTemplate>();
			Type t = assembly.GetType(typeName);
			foreach (Type nestedTy in t.GetNestedTypes()) {
				foreach(TypeRepTemplate nestedRep in  mkTemplates(nestedTy.FullName)) {
					rets.Add(nestedRep);
				}
			}
			TypeRepTemplate retRep = null;
			if (t.IsClass) {
				ClassRepTemplate classRep = new ClassRepTemplate();
				buildClass(classRep, t);
				retRep = classRep;
			}
			else if (t.IsInterface) {
				InterfaceRepTemplate intRep = new InterfaceRepTemplate();
				buildInterface(intRep, t);
				retRep = intRep;
			}
			else if (t.IsEnum) {
				EnumRepTemplate enumRep = new EnumRepTemplate();
				enumRep.TypeName = TypeHelper.buildTypeName(t);
				foreach (FieldInfo f in t.GetFields(BindingFlags.Public | BindingFlags.Static)) {
					enumRep.Members.Add(new EnumMemberRepTemplate(f.Name, f.GetRawConstantValue().ToString()));
				}
				retRep = enumRep;
			}
			rets.Add(retRep);
			return rets;

		}

		private void writeXmlStream(TypeRepTemplate inT, TextWriter str) {
			
			XmlSerializer xmls = new XmlSerializer(inT.GetType(), Constants.TranslationTemplateNamespace);

			XmlWriterSettings settings = new XmlWriterSettings();
        	settings.Encoding = Encoding.UTF8;
        	settings.Indent = true;
        	settings.IndentChars = "\t";
        	settings.NewLineChars = Environment.NewLine;
        	settings.ConformanceLevel = ConformanceLevel.Document;

        	using (XmlWriter writer = XmlTextWriter.Create(str, settings))
        	{
            	xmls.Serialize(writer, inT);
        	}
		}

		private List<string> getAllTypeNames() {
			List<string> typeNames = new List<string>();
			foreach (Type t in assembly.GetExportedTypes()) {
				typeNames.Add(t.FullName);
			}
			return typeNames;
		}
		
		private static void printUsageAndExit() {
			Console.WriteLine ("Help goes here!");
			Environment.Exit(0);
		}

		public static void Main(string[] args) {
			
			TemplateFromDLL templateDriver = new TemplateFromDLL();
			List<string> extractTypes = null;
			bool dumpXmls = false;
			string xmlDir = Directory.GetCurrentDirectory();
  			OptionSet p = new OptionSet ()
    			.Add ("v", v => templateDriver.verbose++)
    			.Add ("help|h|?", v => printUsageAndExit())
    			.Add ("dll=", dllFileName => templateDriver.assembly = Assembly.LoadFile(dllFileName))
    			.Add ("dumpxmls", v => dumpXmls = true)
    			.Add ("xmldir=", dir => xmlDir = Path.Combine(xmlDir, dir));
    		//	.Add ("extract={,}", typeName => templateDriver.extractTypes.Add(typeName));
  			extractTypes = p.Parse (args);
			if (templateDriver.assembly == null) {
				Console.WriteLine("You must specify the DLL to extract the types");
				printUsageAndExit();
			}
			if (extractTypes == null || extractTypes.Count == 0) {
				extractTypes = templateDriver.getAllTypeNames();
			}
			if (templateDriver.verbose > 0)
				Console.WriteLine ("Types to extract:");
			foreach (string t in extractTypes) {
				if (templateDriver.verbose > 0)
					Console.WriteLine (	"extracting {0}", t );
				IList<TypeRepTemplate> tyReps = templateDriver.mkTemplates(t);
				TextWriter writer = null;
				foreach (TypeRepTemplate tyRep in tyReps) {
					if (dumpXmls) {                                
						string xmlFName = Path.Combine(xmlDir, tyRep.TypeName.Replace('.', Path.DirectorySeparatorChar) + ".xml");
	                    string xmlFDir = Path.GetDirectoryName(xmlFName);
	                    if (!Directory.Exists(xmlFDir))
	                    {
	                        Directory.CreateDirectory(xmlFDir);
	                    }
	                    writer = new StreamWriter(xmlFName);
					}
					else {
						writer = Console.Out;
					}
					templateDriver.writeXmlStream(tyRep, writer);
					if (dumpXmls)
	                    writer.Close();
				}
			}	
		}
	}
}

