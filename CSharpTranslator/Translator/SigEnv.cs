using System;
using System.Collections;
using System.Text;


// This is just a holder for parts of a type signature that we need to pass
// from production to production
namespace RusticiSoftware.Translator
{
    public class SigEnv
    {

        public SigEnv()
        { }

        public ArrayList Properties = new ArrayList();

        public ArrayList Methods = new ArrayList();

        public ArrayList Constructors = new ArrayList();

        public ArrayList Fields = new ArrayList();

        public ArrayList Casts = new ArrayList();
    }
}
