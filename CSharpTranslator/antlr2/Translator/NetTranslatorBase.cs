using System;
using System.IO;
using System.Collections;

namespace RusticiSoftware.Translator
{
    // Generate header specific to the tree-parser CSharp file
 

    /** Net Translator Base Class
     *  Really these routines are part of the NetTranslator, but they are pure C# and it is easier
     *  to develop them in a C# class in VS
     *
     * Author: Kevin Glynn <kevin.glynn@scorm.com>
     *
     *
     */
    public class NetTranslatorBase : JavaTreeParser
    {
  
        protected SymbolTable symtab = new SymbolTable();

        //protected TypeRep mkType(string type, int rank)
        //{
        //    return TypeRep.newInstance(type, rank, uPath);
        //}

        public void ExtendSymTabFromNS(string ns)
        {
            ArrayList EmptyPath = new ArrayList();
            DirectoryHT env = (DirectoryHT) TypeRep.TypeEnv[ns];

            if (env != null)
            {
                // Note GetFiles(dir, "*.xml") won't work because of odd search behaviour with 3 letter extensions ....
                foreach (string p in env.Leaves.Keys)
                {
                    TypeRep t = TypeRep.newInstance(ns + "." + p, EmptyPath);
                    symtab.Add(p, t);
                }
            }
        }
    }
}
