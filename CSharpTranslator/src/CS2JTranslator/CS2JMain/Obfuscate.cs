using System;
using System.Reflection;
// Control Eazfuscator.NET

[assembly: Obfuscation(Feature = "code control flow obfuscation", Exclude = false)]
[assembly: Obfuscation(Feature = "Apply to type Twiglet.CS2J.Translator.TypeRep.*: all", Exclude = true, ApplyToMembers = true)]
[assembly: Obfuscation(Feature = "Apply to type Twiglet.CS2J.Translator.Transform.JavaMaker: all", Exclude = true, ApplyToMembers = true)]
[assembly: Obfuscation(Feature = "Apply to type AntlrCSharp.csParser: all", Exclude = true, ApplyToMembers = true)]

