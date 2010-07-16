-- Rebuild cs parser
cd "C:\Documents and Settings\developer\My Documents\gitrepos\cs2j\CSharpTranslator\antlr3\src\cs2j\CSharp"
java -Xmx512m -jar ..\..\..\jar\antlr-3.3.jar cs.g

-- parse one file

src\cs2j\bin\Debug\cs2j.exe -mindriver C:\Documents and Settings\DevUser\My Documents\kgtemp\getClass.cs

-- parse Logic

cd "C:\Documents and Settings\developer\My Documents\gitrepos\cs2j\CSharpTranslator\antlr3"

src\cs2j\bin\Debug\cs2j.exe -netdir "c:\Documents and Settings\s\developer\My Documents\gitrepos\cs2j\CS2JLibrary\NetTranslations" -appdir "c:\Documents and Settings\developer\My Documents\Visual Studio 2005\Projects\ScormEngineNetTrunk\src\app\ScormEngine.Core" "c:\Documents and Settings\developer\My Documents\Visual Studio 2005\Projects\ScormEngineNetTrunk\src\app\ScormEngine.Core\Logic"


-- arguments to VS Debug

-dumpcsharp -dumpxml -xmldir c:\xmls  -netdir "C:\Documents and Settings\developer\My Documents\gitrepos\cs2j\CS2JLibrary\NetTranslations" "C:\Documents and Settings\developer\My Documents\Visual Studio 2005\Projects\ScormEngineNetTrunk\src\app\ScormEngine.Core\Util\Encryption\DataProtection.cs"
