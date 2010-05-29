using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Xml;
using System.Xml.Serialization;

namespace RusticiSoftware.Translator.CLR
{

    public abstract class TranslationBase
    {
        protected TranslationBase()
        {
        }
    }
 
    public class ParamRepTemplate : TranslationBase
    {
 
        public string Type;

        public string Name;

        public ParamRepTemplate() : base()
        {}

        public ParamRepTemplate(string t, string a)
        {
            Type = t;
            Name = a;
        }
 
    }

    public class ConstructorRepTemplate : TranslationBase
    {
        [XmlArrayItem("Import")]
        public string[] Imports;
        [XmlArrayItem("Param")]
        public ParamRepTemplate[] Params;
        public string Java;

        public ConstructorRepTemplate()
            : base()
        {
            Imports = new string[0];
            Params = new ParamRepTemplate[0];
        }

        public ConstructorRepTemplate(ParamRepTemplate[] pars)
            : base()
        {
            Imports = new string[0];
            Params = pars;
        }

        public ConstructorRepTemplate(ParamRepTemplate[] pars, string[] imps, string javaRep)
            : base()
        {
            Imports = imps;
            Params = pars;
            Java = javaRep;
        } 
    }

    public class MethodRepTemplate : ConstructorRepTemplate
    {
        public string Return;
        public string Name;

        public MethodRepTemplate()
        { }

        public MethodRepTemplate(string retType, string methodName,
                                 ParamRepTemplate[] pars, string[] imps, string javaRep)
            : base(pars, imps, javaRep)
        {
            Return = retType;
            Name = methodName;
        }
 
        public MethodRepTemplate(string retType, string methodName,
                                 ParamRepTemplate[] pars)
            : this(retType, methodName, pars, new string[0], null)
        {
        } 

    }

    public class CastRepTemplate : TranslationBase
    {
        [XmlArrayItem("Import")]
        public string[] Imports;
        public string From;
        public string To;
        public string Java;

        public CastRepTemplate()
            : base()
        {
            Imports = new string[0];
        }

        public CastRepTemplate(string fType, string tType,
                                string[] imps, string java)
        {
            From = fType;
            To = tType;
            Imports = imps;
            Java = java;
        }

        public CastRepTemplate(string fType, string tType)
            :
            this(fType, tType, new string[0], null)
        {
        }
    }

    public class FieldRepTemplate : TranslationBase
    {
        [XmlArrayItem("Import")]
        public string[] Imports;
        public string Type;
        public string Name;
        public string Get;

        public FieldRepTemplate()
            : base()
        {
            Imports = new string[0];
        }

        public FieldRepTemplate(string fType, string fName,
                                string[] imps, string javaGet)
        {
            Type = fType;
            Name = fName;
            Imports = imps;
            Get = javaGet;
        }

        public FieldRepTemplate(string fType, string fName)
            :
            this(fType, fName, new string[0], null)
        {
        }
    }

    public class PropRepTemplate : FieldRepTemplate
    {
        public string Set;

        public PropRepTemplate()
            : base()
        { }

        public PropRepTemplate(string fType, string fName,
                                string[] imps, string javaGet, string javaSet)
            : base(fType, fName, imps, javaGet)
        {
            Set = javaSet;
        }

        public PropRepTemplate(string fType, string fName) : this(fType, fName, new string[0], null, null)
        {
        }
                
    }


    // Base Template for classes, interfaces, enums, etc.
    [Serializable]
    public abstract class TypeRepTemplate : TranslationBase
    {

        // Fully qualified Type Name
        [XmlElementAttribute("Name")]
        public string TypeName;

        // Java equivalent of this type (valid given imports)
        public string Java;

        // Path to use when resolving types
        [XmlArrayItem("Namespace")]
        public string[] NamespacePath;

        [XmlArrayItem("Type")]
        public string[] Inherits;
        [XmlArrayItem("Import")]
        public string[] Imports;
        [XmlArrayItem("Method")]
        public MethodRepTemplate[] Methods;
        [XmlArrayItem("Property")]
        public PropRepTemplate[] Properties;
        [XmlArrayItem("Field")]
        public FieldRepTemplate[] Fields;
        [XmlArrayItem("Cast")]
        public CastRepTemplate[] Casts;

        public TypeRepTemplate() : base()
        {
            // If these fields are not specified then these will be zero element arrays (rather than null)
            NamespacePath = new string[0];
            Inherits = new string[0];
            Imports = new string[0];
            Methods = new MethodRepTemplate[0];
            Properties = new PropRepTemplate[0];
            Fields = new FieldRepTemplate[0];
            Casts = new CastRepTemplate[0];
        }

        protected TypeRepTemplate(string typeName)
            : this()
        {
            TypeName = typeName;
        }

        protected TypeRepTemplate(string tName, string[] usePath, string[] inherits,
                                  MethodRepTemplate[] ms, PropRepTemplate[] ps, FieldRepTemplate[] fs,
                                  CastRepTemplate[] cs,
                                  string[] imps, string javaTemplate)
            : base()
        {
            TypeName = tName;
            NamespacePath = usePath;
            Inherits = inherits;
            Methods = ms;
            Properties = ps;
            Fields = fs;
            Imports = imps;
            Casts = cs;
            Java = javaTemplate;
        }

        private static object Deserialize(Stream fs, System.Type t)
        {
            object o = null;

            XmlSerializer serializer = new XmlSerializer(t);
            o = serializer.Deserialize(fs);
            return o;
        }


        private static TypeRepTemplate Deserialize(Stream s)
        {
            TypeRepTemplate ret = null;
            XmlTextReader reader = new XmlTextReader(s);
            string typeType = null;  // class, interface, enum, etc.
            bool found = false;

            try
            {
                while (reader.Read() && !found)
                {
                    if (reader.NodeType == XmlNodeType.Element)
                    {
                        switch (reader.LocalName)
                        {
                            case "Class":
                                typeType = "RusticiSoftware.Translator.ClassRepTemplate";
                                break;
                            case "Interface":
                                typeType = "RusticiSoftware.Translator.InterfaceRepTemplate";
                                break;
                            case "Enum":
                                typeType = "RusticiSoftware.Translator.EnumRepTemplate";
                                break;
                            default:
                                typeType = "UnknownType";
                                break;
                        }
                        found = true;
                    }
                }
                s.Seek(0, SeekOrigin.Begin);
                ret = (TypeRepTemplate)Deserialize(s, System.Type.GetType(typeType));
            }
            catch (Exception e)
            {
                Console.WriteLine("WARNING -- (Deserialize) " + e.Message);
            }

            return ret;
        }


        public static TypeRepTemplate newInstance(Stream s)
        {
            return (TypeRepTemplate)Deserialize(s);
        }

        // Useful because it builds either an empty ClassRep or InterfaceRep or ...
        public abstract TypeRep mkEmptyRep();
    }

    [XmlType("Class")]
    public class ClassRepTemplate : TypeRepTemplate
    {

        [XmlArrayItem("Constructor")]
        public ConstructorRepTemplate[] Constructors = new ConstructorRepTemplate[0];
        
        public ClassRepTemplate()
        {
        }

        public ClassRepTemplate(string typeName) : base(typeName)
        {
        }

        public ClassRepTemplate(string tName, string[] usePath, string[] inherits,
                                ConstructorRepTemplate[] cs,
                                MethodRepTemplate[] ms, PropRepTemplate[] ps, FieldRepTemplate[] fs,
                                CastRepTemplate[] cts,
                                string[] imps, string javaTemplate)
            : base(tName, usePath, inherits, ms, ps, fs, cts, imps, javaTemplate)
        {
            Constructors = cs;
        }

        public ClassRepTemplate(string tName, string[] usePath, string[] inherits,
                        ConstructorRepTemplate[] cs,
                        MethodRepTemplate[] ms, PropRepTemplate[] ps, FieldRepTemplate[] fs, CastRepTemplate[] cts)
            : base(tName, usePath, inherits, ms, ps, fs, cts, new String[0], null)
        {
            Constructors = cs;
        }

        public override TypeRep mkEmptyRep()
        {
            return new ClassRep();
        }


    }

    [XmlType("Interface")]
    public class InterfaceRepTemplate : TypeRepTemplate
    {
        public InterfaceRepTemplate()
        { }

        public InterfaceRepTemplate(string typeName)
            : base(typeName)
        {
        }

        public InterfaceRepTemplate(string tName, string[] usePath, string[] inherits,
                               MethodRepTemplate[] ms, PropRepTemplate[] ps, FieldRepTemplate[] fs,
                               CastRepTemplate[] cts,
                               string[] imps, string javaTemplate)
            : base(tName, usePath, inherits, ms, ps, fs, cts, imps, javaTemplate)
        { }

        public override TypeRep mkEmptyRep()
        {
            return new InterfaceRep();
        }
    }

    [XmlType("Enum")]
    public class EnumRepTemplate : TypeRepTemplate
    {
        public EnumRepTemplate()
        { }

        public EnumRepTemplate(string typeName)
            : base(typeName)
        {
        }

        public EnumRepTemplate(string tName, string[] usePath, string[] inherits,
                               MethodRepTemplate[] ms, PropRepTemplate[] ps, FieldRepTemplate[] fs,
                               CastRepTemplate[] cts,
                               string[] imps, string javaTemplate)
            : base(tName, usePath, inherits, ms, ps, fs, cts, imps, javaTemplate)
        { }

        public override TypeRep mkEmptyRep()
        {
            return new EnumRep();
        }
    }

    [XmlType("Struct")]
    public class StructRepTemplate : ClassRepTemplate
    {

        public StructRepTemplate()
        {
        }

        public StructRepTemplate(string typeName) : base(typeName)
        {
        }

        public StructRepTemplate(string tName, string[] usePath, string[] inherits,
                                ConstructorRepTemplate[] cs,
                                MethodRepTemplate[] ms, PropRepTemplate[] ps, FieldRepTemplate[] fs,
                                CastRepTemplate[] cts,
                                string[] imps, string javaTemplate)
            : base(tName, usePath, inherits, cs, ms, ps, fs, cts, imps, javaTemplate)
        {
        }

        public StructRepTemplate(string tName, string[] usePath, string[] inherits,
                        ConstructorRepTemplate[] cs,
                        MethodRepTemplate[] ms, PropRepTemplate[] ps, FieldRepTemplate[] fs, CastRepTemplate[] cts)
            : base(tName, usePath, inherits, cs, ms, ps, fs, cts, new String[0], null)
        {
        }

        public override TypeRep mkEmptyRep()
        {
            return new StructRep();
        }

    }

}
