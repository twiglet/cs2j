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
using System.Reflection;
using System.IO;
using System.Xml.Serialization;
using System.Xml;
using System.Text;
using NDesk.Options;
using System.Collections.Generic;
using Twiglet.CS2J.Translator.TypeRep;
using Twiglet.CS2J.Translator.Utils;
using Twiglet.CS2J.Utility.Utils;

namespace Twiglet.CS2J.Utility
{
    public class TemplateFromDLL
    {
        private const string CS2JTEMPLATE_VERSION = "pre-release";
        private Assembly assembly = null;
        private int verbose = 0;

        public TemplateFromDLL(string DLLFileName)
        {
            assembly = Assembly.LoadFile(DLLFileName);
        }

        public TemplateFromDLL()
        {
        }


        public void listTypes(string DLLFileName)
        {

            Assembly testAssembly = Assembly.LoadFile(DLLFileName);

            Type[] exportedTypes = testAssembly.GetExportedTypes();

            Console.WriteLine("Enums:");
            foreach (Type item in exportedTypes)
            {
                if (item.IsEnum)
                {
                    Console.WriteLine(" * " + TypeHelper.buildTypeName(item));
                }
            }

            Console.WriteLine("Interfaces:");
            foreach (Type item in exportedTypes)
            {
                if (item.IsInterface)
                {
                    Console.WriteLine(" * " + TypeHelper.buildTypeName(item));
                }
            }
            Console.WriteLine("Classes:");
            foreach (Type item in exportedTypes)
            {
                if (item.IsClass)
                {
                    Console.WriteLine(" * " + TypeHelper.buildTypeName(item));
                }
            }
            Console.WriteLine("Arrays:");
            foreach (Type item in exportedTypes)
            {
                if (item.IsArray)
                {
                    Console.WriteLine(" * " + TypeHelper.buildTypeName(item));
                }
            }
            Console.WriteLine("Others:");
            foreach (Type item in exportedTypes)
            {
                if (!item.IsEnum && !item.IsInterface && !item.IsClass && !item.IsArray)
                {
                    Console.WriteLine(" * " + TypeHelper.buildTypeName(item));
                }
            }

        }

        private void buildParameters(IList<ParamRepTemplate> ps, MethodBase m)
        {
            foreach (ParameterInfo p in m.GetParameters())
            {
                ParamRepTemplate paramRep = new ParamRepTemplate();
                paramRep.Type = new TypeRepRef(TypeHelper.buildTypeName(p.ParameterType));
                paramRep.Name = p.Name;
                ps.Add(paramRep);
            }
        }

        private void buildInterface(InterfaceRepTemplate iface, Type t)
        {

            if (t.IsGenericType)
            {
                iface.TypeName = t.GetGenericTypeDefinition().FullName;
                string[] tParams = new string[t.GetGenericArguments().Length];
                for (int i = 0; i < t.GetGenericArguments().Length; i++)
                {
                    tParams[i] = t.GetGenericArguments()[i].Name;
                }
                iface.TypeParams = tParams;
            }
            else
            {
                iface.TypeName = t.FullName;
            }

            List<String> bases = new List<String>();
            if (t.BaseType != null)
                bases.Add(TypeHelper.buildTypeName(t.BaseType));
            foreach (Type iTy in t.GetInterfaces())
            {
                bases.Add(TypeHelper.buildTypeName(iTy));
            }

            iface.Inherits = bases.ToArray();

            // Grab Methods
            foreach (MethodInfo m in t.GetMethods(BindingFlags.DeclaredOnly | BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance))
            {
                if (m.IsSpecialName)
                {
                    // e.g., a property's getter / setter method
                    continue;
                }
                MethodRepTemplate methRep = new MethodRepTemplate();
                methRep.Name = m.Name;
                methRep.Return = new TypeRepRef(TypeHelper.buildTypeName(m.ReturnType));
                if (m.IsGenericMethod)
                {
                    string[] tParams = new string[m.GetGenericArguments().Length];
                    for (int i = 0; i < m.GetGenericArguments().Length; i++)
                    {
                        tParams[i] = m.GetGenericArguments()[i].Name;
                    }
                    methRep.TypeParams = tParams;
                }
                buildParameters(methRep.Params, m);
                if (m.IsStatic)
                {
                    methRep.IsStatic = true;
                }
                methRep.SurroundingType = iface;
                iface.Methods.Add(methRep);
            }

            // Grab Properties
            foreach (PropertyInfo p in t.GetProperties())
            {
                PropRepTemplate propRep = new PropRepTemplate();
                propRep.Name = p.Name;
                propRep.Type = new TypeRepRef(TypeHelper.buildTypeName(p.PropertyType));
                propRep.CanRead = p.CanRead;
                propRep.CanWrite = p.CanWrite;
                iface.Properties.Add(propRep);
            }

            // Grab Events
            foreach (EventInfo e in t.GetEvents())
            {
                FieldRepTemplate eventRep = new FieldRepTemplate();
                eventRep.Name = e.Name;
                eventRep.Type = new TypeRepRef(TypeHelper.buildTypeName(e.EventHandlerType));
                iface.Events.Add(eventRep);
            }
        }

        private void buildClass(ClassRepTemplate klass, Type t)
        {
            // Grab common fields
            buildInterface(klass, t);
            // Grab Constructors
            foreach (ConstructorInfo c in t.GetConstructors())
            {
                ConstructorRepTemplate consRep = new ConstructorRepTemplate();
                buildParameters(consRep.Params, c);
                consRep.SurroundingType = klass;
                klass.Constructors.Add(consRep);
            }
            // Grab Fields
            foreach (FieldInfo f in t.GetFields())
            {
                FieldRepTemplate fieldRep = new FieldRepTemplate();
                fieldRep.Name = f.Name;
                fieldRep.Type = new TypeRepRef(TypeHelper.buildTypeName(f.FieldType));
                klass.Fields.Add(fieldRep);
            }
            // Grab Casts
            foreach (MethodInfo m in t.GetMethods(BindingFlags.DeclaredOnly | BindingFlags.Public | BindingFlags.Static))
            {
                if (m.IsSpecialName && (m.Name == "op_Explicit" || m.Name == "op_Implicit"))
                {
                    CastRepTemplate cast = new CastRepTemplate();
                    cast.To = new TypeRepRef(TypeHelper.buildTypeName(m.ReturnType));
                                             cast.From = new TypeRepRef(TypeHelper.buildTypeName(m.GetParameters()[0].ParameterType));
                    klass.Casts.Add(cast);
                }

            }

        }

        private void buildDelegate(DelegateRepTemplate d, Type t)
        {

            if (t.IsGenericType)
            {
                d.TypeName = t.GetGenericTypeDefinition().FullName;
                string[] tParams = new string[t.GetGenericArguments().Length];
                for (int i = 0; i < t.GetGenericArguments().Length; i++)
                {
                    tParams[i] = t.GetGenericArguments()[i].Name;
                }
                d.TypeParams = tParams;
            }
            else
            {
                d.TypeName = t.FullName;
            }

            MethodInfo invoker = t.GetMethod("Invoke");
            if (invoker == null)
                throw new Exception("Unexpected: class " + t.FullName + " inherits from System.Delegate but doesn't have an Invoke method");
            List<ParamRepTemplate> pars = new List<ParamRepTemplate>();
            buildParameters(pars, invoker);
            d.Invoke = new InvokeRepTemplate(TypeHelper.buildTypeName(invoker.ReturnType), "Invoke", null, pars);
        }

        private IList<TypeRepTemplate> mkTemplates(string typeName)
        {

            List<TypeRepTemplate> rets = new List<TypeRepTemplate>();
            Type t = assembly.GetType(typeName);
            if (t == null)
                throw new Exception(String.Format("Type {0} not found", typeName));
            foreach (Type nestedTy in t.GetNestedTypes())
            {
                foreach (TypeRepTemplate nestedRep in mkTemplates(nestedTy.FullName))
                {
                    rets.Add(nestedRep);
                }
            }
            TypeRepTemplate retRep = null;
            if (t.IsClass)
            {
                if (t.IsSubclassOf(typeof(System.Delegate)))
                {
                    DelegateRepTemplate delRep = new DelegateRepTemplate();
                    buildDelegate(delRep, t);
                    retRep = delRep;
                }
                else
                {
                    ClassRepTemplate classRep = new ClassRepTemplate();
                    buildClass(classRep, t);
                    retRep = classRep;
                }
            }
            else if (t.IsInterface)
            {
                InterfaceRepTemplate intRep = new InterfaceRepTemplate();
                buildInterface(intRep, t);
                retRep = intRep;
            }
            else if (t.IsEnum)
            {
                EnumRepTemplate enumRep = new EnumRepTemplate();
                enumRep.TypeName = TypeHelper.buildTypeName(t);
                foreach (FieldInfo f in t.GetFields(BindingFlags.Public | BindingFlags.Static))
                {
                    enumRep.Members.Add(new EnumMemberRepTemplate(f.Name, f.GetRawConstantValue().ToString()));
                }
                retRep = enumRep;
            }
            rets.Add(retRep);
            return rets;

        }

        private void writeXmlStream(TypeRepTemplate inT, TextWriter str)
        {

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

        private List<string> getAllTypeNames()
        {
            List<string> typeNames = new List<string>();
            foreach (Type t in assembly.GetExportedTypes())
            {
                typeNames.Add(t.FullName);
            }
            return typeNames;
        }

        private static void printUsageAndExit()
        {
            Console.Out.WriteLine("Usage: " + Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]) + " <type to dump, if not given dump all>");
            Console.Out.WriteLine(" [-version]                                            (show version information)");
            Console.Out.WriteLine(" [-help|h|?]                                           (this usage message)");
            Console.Out.WriteLine(" [-v]                                                  (be [somewhat more] verbose, repeat for more verbosity)");
            Console.Out.WriteLine(" -dll <path to dll>                                    (path to dll)");
            Console.Out.WriteLine(" [-listtypes]                                          (show types in DLL and exit)");
            Console.Out.WriteLine(" [-dumpxml] [-xmldir <directory to dump xml database>] (dump the translation repository as xml files)");
            Environment.Exit(0);
        }

        private static void printVersion()
        {
            Console.Out.WriteLine(Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]));
            Console.WriteLine("Version: {0}", CS2JTEMPLATE_VERSION);
        }

        public static void Main(string[] args)
        {

            TemplateFromDLL templateDriver = new TemplateFromDLL();
            List<string> extractTypes = null;
            bool dumpXmls = false;
            bool listTypes = false;
            string xmlDir = Directory.GetCurrentDirectory();
            OptionSet p = new OptionSet()
                .Add("v", v => templateDriver.verbose++)
                .Add("version", v => printVersion())
                .Add("help|h|?", v => printUsageAndExit())
                .Add("dll=", dllFileName => templateDriver.assembly = Assembly.LoadFile(dllFileName))
                .Add("listtypes", v => listTypes = true)
                .Add("dumpxmls", v => dumpXmls = true)
                .Add("xmldir=", dir => xmlDir = Path.Combine(xmlDir, dir));
            //	.Add ("extract={,}", typeName => templateDriver.extractTypes.Add(typeName));
            extractTypes = p.Parse(args);
            if (templateDriver.assembly == null)
            {
                Console.WriteLine("You must specify the DLL");
                printUsageAndExit();
            }
            if (extractTypes == null || extractTypes.Count == 0)
            {
                extractTypes = templateDriver.getAllTypeNames();
            }
            if (listTypes)
            {
                Console.WriteLine("All Types found in DLL {0}", templateDriver.assembly.FullName);
                foreach (string item in templateDriver.getAllTypeNames())
                {
                    Console.WriteLine(item);
                }
                Environment.Exit(0);
            }
            if (templateDriver.verbose > 0)
                Console.WriteLine("Types to extract:");
            foreach (string t in extractTypes)
            {
                if (templateDriver.verbose > 0)
                    Console.WriteLine("extracting {0}", t);
                IList<TypeRepTemplate> tyReps = templateDriver.mkTemplates(t);
                TextWriter writer = null;
                foreach (TypeRepTemplate tyRep in tyReps)
                {
                    if (tyRep == null)
                    {
                        if (templateDriver.verbose > 1)
                        {
                            // TODO:  We fail for enumeraters, others?
                            Console.WriteLine("Null typerep found, skipping");
                        }
                        continue;
                    }
                    if (dumpXmls)
                    {
                        string xmlFName = Path.Combine(xmlDir, tyRep.TypeName.Replace('.', Path.DirectorySeparatorChar) + ".xml");
                        string xmlFDir = Path.GetDirectoryName(xmlFName);
                        if (!Directory.Exists(xmlFDir))
                        {
                            Directory.CreateDirectory(xmlFDir);
                        }
                        writer = new StreamWriter(xmlFName);
                    }
                    else
                    {
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

