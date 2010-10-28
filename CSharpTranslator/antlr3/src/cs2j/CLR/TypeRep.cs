using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Xml.Serialization;
//using T = RusticiSoftware.Translator.CSharpJavaTokenTypes;  // We want easy access to the Token mappings

using RusticiSoftware.Translator.Utils;

namespace RusticiSoftware.Translator.CLR
{

    public abstract class RepBase
    {

        protected static DirectoryHT<TypeRepTemplate> TypeTemplateCache = new DirectoryHT<TypeRepTemplate>();
        // 

        protected const string TYPEVAR = "${TYPE}";
        
        protected RepBase()
        {
        }

    }
 
    public class ParamRep : RepBase
    {
        private TypeRep _type;

        public TypeRep Type
        {
            get { return _type; }
            set { _type = value; }
        }

        private string _arg;

        public string Name
        {
            get { return _arg; }
            set { _arg = value; }
        }

        public ParamRep()
        {}

        public ParamRep(TypeRep t, string a)
        {
            _type = t;
            _arg = a;
        }


        internal static ParamRep newInstance(ParamRepTemplate pt, ICollection pth)
        {
            ParamRep ret = new ParamRep();
            ret.Name = pt.Name;
            ret.Type = TypeRep.newInstance(pt.Type, pth);
            return ret;
        }
    }


    public class ConstructorRep : RepBase
    {
        private string[] _imports;

        public string[] Imports
        {
            get { return _imports; }
            set { _imports = value; }
        }

        private ParamRep[] _params;

        public ParamRep[] Params
        {
            get { return _params; }
            set { _params = value; }
        }

        private string _javaRep;

        public string Java
        {
            get { return _javaRep; }
            set { _javaRep = value; }
        }

        public ConstructorRep() : base()
        {
        }

        public ConstructorRep(ParamRep[] pars, string javaRep) : base()
        {
            _params = pars;
            _javaRep = javaRep;
        }


        public ConstructorRep(ConstructorRepTemplate ct, ICollection pth)
        {
            Params = new ParamRep[ct.Params.Count];
            for (int i = 0; i < ct.Params.Count; i++)
            {
                Params[i] = ParamRep.newInstance(ct.Params[i], pth);
            }
            Imports = new string[ct.Imports.Length];
            for (int i = 0; i < ct.Imports.Length; i++)
            {
                Imports[i] = ct.Imports[i];
            }
            Java = ct.Java;
        }
    }
    
    public class MethodRep : ConstructorRep
    {

        private TypeRep _retType;

        public TypeRep Return
        {
            get { return _retType; }
            set { _retType = value; }
        }

        private string _methodName;

        public string Name
        {
            get { return _methodName; }
            set { _methodName = value; }
        }


        public MethodRep() : base()
        {
        }

        public MethodRep(MethodRepTemplate mt, ICollection pth) : base(mt, pth)
        {
            Name = mt.Name;
            Return = TypeRep.newInstance(mt.Return, pth);
       } 
    }

    public class CastRep : RepBase
    {
        private string[] _imports;

        public string[] Imports
        {
            get { return _imports; }
            set { _imports = value; }
        }

        private TypeRep _fType;

        public TypeRep FromType
        {
            get { return _fType; }
            set { _fType = value; }
        }

        private TypeRep _tType;

        public TypeRep ToType
        {
            get { return _tType; }
            set { _tType = value; }
        }
        private string _javaRep;

        public string Java
        {
            get { return _javaRep; }
            set { _javaRep = value; }
        }

       public CastRep()
            : base()
        {
        }

        public CastRep(CastRepTemplate ct, ICollection pth)
        {
            FromType = TypeRep.newInstance(ct.From, pth);
            ToType = TypeRep.newInstance(ct.To, pth);
            Java = ct.Java;
            Imports = new string[ct.Imports.Length];
            for (int i = 0; i < ct.Imports.Length; i++)
            {
                Imports[i] = ct.Imports[i];
            }
        }

        internal static CastRep newInstance(CastRepTemplate ct, ICollection pth)
        {
            return new CastRep(ct, pth);
        }
    }

    public class FieldRep : RepBase
    {
        private string[] _imports;

        public string[] Imports
        {
            get { return _imports; }
            set { _imports = value; }
        }

        private TypeRep _type;

        public TypeRep Type
        {
            get { return _type; }
            set { _type = value; }
        }

        private string _name;

        public string Name
        {
            get { return _name; }
            set { _name = value; }
        }
        private string _javaGetRep;

        public string Get
        {
            get { return _javaGetRep; }
            set { _javaGetRep = value; }
        }

        private string _javaSetRep;

        public string Set
        {
            get { return _javaSetRep; }
            set { _javaSetRep = value; }
        }

        public FieldRep()
            : base()
        {
        }

        public FieldRep(FieldRepTemplate ft, ICollection pth)
        {
            Name = ft.Name;
            Type = TypeRep.newInstance(ft.Type, pth);
            Get = ft.Java;
            Imports = new string[ft.Imports.Length];
            for (int i = 0; i < ft.Imports.Length; i++)
            {
                Imports[i] = ft.Imports[i];
            }
        }

        internal static FieldRep newInstance(FieldRepTemplate ft, ICollection pth)
        {
            return new FieldRep(ft, pth);
        }
    }

    public class PropRep : FieldRep
    {
        public PropRep() : base()
        { }

        public PropRep(PropRepTemplate pt, ICollection pth) : base(pt, pth)
        {
            Set = pt.JavaSet;
        }


        internal static PropRep newInstance(PropRepTemplate pt, ICollection pth)
        {
            return new PropRep(pt, pth);
        }
    }

    public class TypeRep : RepBase
    {
        private static Hashtable TypeRepCache = new Hashtable();

        public static void Initialize(DirectoryHT<TypeRepTemplate> e)
        {
            TypeTemplateCache = e;
        }

        public static DirectoryHT<TypeRepTemplate> TypeEnv
        {
            get { return TypeTemplateCache; }
        }

        private string _typeName;
        private string _java;
        private TypeRep _extends;
        private TypeRep[] _implements;

        public string TypeName
        {
            get { return _typeName; }
            set { _typeName = value; }
        }

        public string Java
        {
            get { return _java; }
            set { _java = value; }
        }

        public TypeRep Extends
        {
            get { return _extends; }
            set { _extends = value; }
        }
        public TypeRep[] Implements
        {
            get { return _implements; }
            set { _implements = value; }
        }

        private string[] _imports;
        public string[] Imports
        {
            get { return _imports; }
            set { _imports = value; }
        }

        private Hashtable _methodsD = new Hashtable(); 
        public Hashtable MethodsD
        {
            get { return _methodsD; }
            set { _methodsD = value; }
        }

        private Hashtable _propsD = new Hashtable();  
        public Hashtable PropertiesD
        {
            get { return _propsD; }
            set { _propsD = value; }
        }

        private Hashtable _fieldsD = new Hashtable();  
        public Hashtable FieldsD
        {
            get { return _fieldsD; }
            set { _fieldsD = value; }
        }

        private CastRep[] _casts;
        public CastRep[] Casts
        {
            get { return _casts; }
            set { _casts = value; }
        }

        protected TypeRep()
            : base()
        {
        }

        // Dummy Type
        protected TypeRep(string name)
            : base()
        {
            TypeName = name;
            Extends = null;
            Implements = new TypeRep[0];
            Imports = new string[0];
            MethodsD = new Hashtable();
            PropertiesD = new Hashtable();
            FieldsD = new Hashtable();
            Casts = new CastRep[0];
        }

        protected TypeRep(TypeRepTemplate template) : this()
        {
            Build(template);
        }

        public virtual void Build(TypeRepTemplate template)
        {
            ICollection uPath = template.Uses;

            TypeName = template.TypeName;
            Java = template.Java;
/*
            Imports = new string[template.Imports.Length];
            for (int i = 0; i < template.Imports.Length; i++)
            {
                Imports[i] = template.Imports[i];
            }

            //Extends = TypeRep.newInstance(template.Extends, uPath);
            //Implements = new TypeRep[template.Implements.Length];
            ArrayList TmpImplements = new ArrayList();
            Extends = null;

            for (int i = 0; i < template.Inherits.Length; i++)
            {
                TypeRep trep = TypeRep.newInstance(template.Inherits[i], uPath);
                if (trep is ClassRep)
                {
                    if (Extends != null)
                    {
                        Console.Error.Write("Error -- (TypeRep.Build): " + TypeName + " extends more than one type (");
                        Console.Error.WriteLine(Extends.TypeName + " and " + trep.TypeName + ")");
                    }
                    else
                        Extends = trep;
                }
                else
                    TmpImplements.Add(trep);
            }
            if (Extends == null && TypeName != "System.Object")
                Extends = TypeRep.newInstance("System.Object");

            Implements = (TypeRep[]) TmpImplements.ToArray(typeof(TypeRep));
            FieldsD = new Hashtable();
            foreach (FieldRepTemplate ft in template.Fields)
            {
                FieldsD.Add(ft.Name, FieldRep.newInstance(ft, uPath));
            }
            Casts = new CastRep[template.Casts.Length];
            for (int i = 0; i < template.Casts.Length; i++)
            {
                Casts[i] = CastRep.newInstance(template.Casts[i], uPath);
            }
            PropertiesD = new Hashtable();
            foreach (PropRepTemplate pt in template.Properties)
            {
                PropertiesD.Add(pt.Name, PropRep.newInstance(pt, uPath));
            }
            MethodsD = new Hashtable();
            foreach (MethodRepTemplate mt in template.Methods)
            {
                ArrayList ms = (ArrayList)MethodsD[mt.Name];
                if (ms == null)
                    ms = new ArrayList();

                ms.Add(new MethodRep(mt, uPath));
                MethodsD[mt.Name] = ms;
            }
  */
		}

        private static ClassRep newInstance(ClassRepTemplate template)
        {
            return new ClassRep(template);
        }

        private static InterfaceRep newInstance(InterfaceRepTemplate template)
        {
            return new InterfaceRep(template);
        }

        // While we are constructing a parameterized type (an array), we store
        // the base type here.  This can probably become a dictionary when we
        // need to build instances of generic types.
        private static TypeRep __baseType = null;


        // Finds a template for typeName by searching the path.  typeName must not be an array
        // type (i.e. end with [])
        private static TypeRepTemplate TemplateSearch(string typeName, ICollection pth)
        {
            TypeRepTemplate ret = null;
            DirectoryHT<TypeRepTemplate> ns;

            foreach (string p in pth)
            {
                ns = TypeTemplateCache.subDir(p);
                ret = (ns == null ? null : ns[typeName] as TypeRepTemplate);
                if (ret != null)
                    break;
            }

            // Must Search the Global NameSpace too
            if (ret == null)
                ret = TypeTemplateCache[typeName] as TypeRepTemplate;

            // If all else fails create a dummy typerep
            if (ret == null)
            {
                // Oh Dear, shouldn't happen.
                Console.WriteLine("WARNING:  (TypeRep.TemplateSearch) -- Could not find a template for " + typeName);
                ret = new InterfaceRepTemplate(typeName);
            }

            return ret;
        }

        public static TypeRep newInstance(string typeName, ICollection pth)
        {
            string baseName = typeName;
            int rank = 0;
            string arraySuffix = "";

            // Necessary (only) for the parent of System.Object.
            if (typeName == null)
                return null;

            if (typeName == TYPEVAR)
                // keving: gross hack, see above comment.
                return __baseType;

            // Calculate full, qualified type name and array rank
            while (baseName.EndsWith("[]"))
            {
                rank++;
                arraySuffix += "[]";
                baseName = baseName.Substring(0, baseName.Length - 2);
            }

            // Find the template (and the type's full name)
            TypeRepTemplate template = TemplateSearch(baseName, pth);
            if (template == null)
            {
                // Oh Dear, shouldn't happen.
                Console.WriteLine("WARNING:  (TypeRep.newInstance) -- Could not find a template for " + baseName);
                return null; 
            }

            return newInstance(template.TypeName+arraySuffix, template, rank);
        }

        private readonly static ArrayList EmptyPath = new ArrayList();

        public static TypeRep newInstance(string typeName)
        {
            return newInstance(typeName, EmptyPath);
        }

        private static TypeRep newInstance(string fullTypeName, TypeRepTemplate baseTemplate, int rank)
        {
            TypeRep retRep = null;

            if (TypeRepCache[fullTypeName] != null)
                // Here is one we made earlier
                return (TypeRep)TypeRepCache[fullTypeName];

            
            // Place a dummy typeRep in the cache
            if (rank > 0)
            {
                // Will eventually be the array typerep
                retRep = new ClassRep();
                TypeRepCache[fullTypeName] = retRep;
                TypeRep savedType = __baseType;
                __baseType = newInstance(fullTypeName.Substring(0, fullTypeName.Length - 2), baseTemplate, rank-1);
                retRep.Build(TemplateSearch("System.Array", new ArrayList()));
                retRep.TypeName = fullTypeName;
                __baseType = savedType;
            }
            else
            {
                retRep = baseTemplate.mkEmptyRep();
                // TODO: keving - nicer fix required!
                if (fullTypeName != "System.Array") TypeRepCache[fullTypeName] = retRep;
                retRep.Build(baseTemplate);
            }

            return retRep;
        }

        // Returns true iff child is a subclass of parent.
        //public bool IsA(ASTNode child)
        //{
        //    if (child == null)
        //        return false;

        //    // Is Child a manifest NULL constant?
        //    if (child.Type == T.NULL || 
        //        (child.Type == T.EXPR && child.getFirstChild().Type == T.NULL))
        //        return true;

        //    return IsA(child.DotNetType);

        //}
                    
        // Returns true iff child is a subclass of parent.
        public bool IsA(TypeRep child)
        {

            if (child == null)
                return false;

            if (child.TypeName.EndsWith("[]"))
            {
                if (TypeName == "System.Array")
                    return true;
                if (TypeName.EndsWith("[]"))
                    // true if basetypes are parent-child
                    return Extends.IsA(child.Extends);
                return false;
            }
            // Non-array child
            if (TypeName == child.TypeName)
                return true;
            // Are we any of child's parents, or interfaces
            if (IsA(child.Extends))
                return true;
            foreach (TypeRep t in child.Implements)
            {
                if (IsA(t))
                    return true;
            }
            return false;
        }

        // 
        public FieldRep Resolve(string fieldOrProp)
        {
            FieldRep ret = (FieldRep) PropertiesD[fieldOrProp];
            if (ret == null)
                ret = (FieldRep) FieldsD[fieldOrProp];
            if (ret == null && Extends != null)
                return Extends.Resolve(fieldOrProp);
            return ret;
        }

        public MethodRep Resolve(string method, IList ArgVs)
        {
            MethodRep ret = null;

            if (MethodsD.Contains(method))
            {
                foreach (MethodRep m in (ArrayList) MethodsD[method])
                {
                    if (m.Params.Length == ArgVs.Count)
                    {
                        ret = m;
                        for (int i = 0; i < ArgVs.Count; i++)
                        {
                  // keving          if (!m.Params[i].Type.IsA((ASTNode)ArgVs[i]))
                            {
                                ret = null;  // reset to null, this method doesn't match
                                break;
                            }
                        }
                    }
                    if (ret != null)
                        break;
                }
            }
            // If not found, check parents
            if (ret == null && Extends != null)
                ret = Extends.Resolve(method, ArgVs);
            // If still not found check interfaces
            if (ret == null)
            {
                foreach (TypeRep t in Implements)
                {
                    ret = t.Resolve(method, ArgVs);
                    if (ret != null)
                        break;
                }
            }
            return ret;
        }

        private CastRep ResolveCastFrom(TypeRep from, bool onlyAny)
        {
            CastRep ret = null;
            foreach (CastRep c in Casts)
            {
                if (c.FromType.IsA(from) && 
                    ((onlyAny && c.ToType == null) || (!onlyAny && c.ToType != null && c.ToType.IsA(this))))
                {
                    ret = c;
                    break;
                }
            }
            if (ret == null)
            {
                // Check if compatible cast in our parent, but we can only 
                // have casts that are valid for any descendant
                if (Extends != null)
                    return ((ClassRep)Extends).ResolveCastFrom(from, true);
            }
            return ret;
        }

        public CastRep ResolveCastFrom(TypeRep from)
        {
            return ResolveCastFrom(from, false);
        }

        public CastRep ResolveCastTo(TypeRep to)
        {
            CastRep ret = null;
            foreach (CastRep c in Casts)
            {
                if (c.FromType.IsA(this) && (c.ToType == null || c.ToType.IsA(to)))
                {
                    ret = c;
                    break;
                }
            }
            if (ret == null)
            {
                // Check if compatible cast in parents
                if (Extends != null)
                    return ((ClassRep)Extends).ResolveCastTo(to);
            }
            return ret;
        }

        // c.f. Type.IsAssignableFrom in .Net
        //
        // Returns true iff c and the current TypeRep represent the same type, or if the current TypeRep is 
        // in the inheritance hierarchy of c, or if the current TypeRep is an interface that c implements, 
        // or [if c is a generic type parameter and the current Type represents one of the constraints of c]. 
        // false if none of these conditions are true, or if c is a null reference.
        public bool IsAssignableFrom(TypeRep c)
        {
            return true;
        }

        public static void Test()
        {
        
        }
    }

    public class ClassRep : TypeRep
    {
        private ConstructorRep[] _Constructors = new ConstructorRep[0];

        public ConstructorRep[] Constructors
        {
            get { return _Constructors; }
            set { _Constructors = value; }
        }

        public ClassRep()
            : base()
        { }

        // Dummy type
        public ClassRep(string name)
            : base(name)
        {
        }

        public ClassRep(ClassRepTemplate template)
            : base(template)
        {
            Constructors = new ConstructorRep[template.Constructors.Count];
            for (int i = 0; i < template.Constructors.Count; i++)
            {
                Constructors[i] = new ConstructorRep(template.Constructors[i], template.Uses);
            }
        }

        public override void Build(TypeRepTemplate template)
        {
            ClassRepTemplate ctemp = (ClassRepTemplate)template;
            Constructors = new ConstructorRep[ctemp.Constructors.Count];
            for (int i = 0; i < ctemp.Constructors.Count; i++)
            {
                Constructors[i] = new ConstructorRep(ctemp.Constructors[i], ctemp.Uses);
            }

            base.Build(template);
 
        }

        public ConstructorRep Resolve(IList ArgVs)
        {
            ConstructorRep ret = null;
            foreach (ConstructorRep c in Constructors)
            {
                if (c.Params.Length == ArgVs.Count)
                {
                    ret = c;
                    for (int i = 0; i < ArgVs.Count; i++)
                    {
             // keving           if (!c.Params[i].Type.IsA((ASTNode)ArgVs[i]))
                        {
                            ret = null;  // reset to null, this method doesn't match
                            break;
                        }
                    }
                }
                if (ret != null)
                    break;
            }
            if (ret == null)
            {
                // Check if compatible constructor in parents
                if (Extends != null)
                    return ((ClassRep)Extends).Resolve(ArgVs);
            }
            return ret;
        }


    }

    public class InterfaceRep : TypeRep
    {

        public InterfaceRep()
            : base()
        { }

        // Dummy Interface
        public InterfaceRep(string name)
            : base(name)
        {
        }

        public InterfaceRep(InterfaceRepTemplate template)
            : base(template)
        {
        }

        public override void Build(TypeRepTemplate template)
        {
            base.Build(template);
        }
    }

    public class EnumRep : TypeRep
    {
        // stores the enum constants by value
        string[] fieldsA = new string[0];

        public EnumRep()
            : base()
        { }

        // Dummy Enum
        public EnumRep(string name)
            : base(name)
        {
        }

        public EnumRep(EnumRepTemplate template)
            : base(template)
        {
            int numfields = template.Members.Count;
            fieldsA = new string[numfields];
            for (int i = 0; i < numfields; i++)
                fieldsA[i] = template.Members[i].Name;
        }

        public void Build(EnumRepTemplate template)
        {
            int numfields = template.Members.Count;
            fieldsA = new string[numfields];
            for (int i = 0; i < numfields; i++)
                fieldsA[i] = template.Members[i].Name;
            base.Build(template);
        }

        public string getField(int v)
        {
            return fieldsA[v];
        }
    }

   public class StructRep : TypeRep
   {

        public StructRep()
            : base()
        { }

        // Dummy Struct
        public StructRep(string name)
            : base(name)
        {
        }

        public StructRep(StructRepTemplate template)
            : base(template)
        {
        }

        public override void Build(TypeRepTemplate template)
        {
            base.Build(template);
        }
    }

   public class DelegateRep : TypeRep
   {

        public DelegateRep()
            : base()
        { }

        // Dummy Delegate
        public DelegateRep(string name)
            : base(name)
        {
        }

        public DelegateRep(DelegateRepTemplate template)
            : base(template)
        {
        }

        public override void Build(TypeRepTemplate template)
        {
            base.Build(template);
        }
    }
}
