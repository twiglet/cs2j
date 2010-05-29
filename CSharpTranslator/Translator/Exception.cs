using System;
using System.Collections.Generic;
using System.Text;

namespace RusticiSoftware.Translator
{
    class CorruptCompilationUnit : Exception
    {
        ASTNode ast = null;

        public CorruptCompilationUnit(ASTNode astIn)
        {
            ast = astIn;
        }
    }

    class UnexpectedAST : Exception
    {
        ASTNode ast = null;

        public UnexpectedAST(ASTNode astIn)
        {
            ast = astIn;
        }
    }
}
